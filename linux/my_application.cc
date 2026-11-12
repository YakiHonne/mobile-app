#include "my_application.h"

#include <flutter_linux/flutter_linux.h>
#ifdef GDK_WINDOWING_X11
#include <gdk/gdkx.h>
#endif

#include <cstring>

#include "flutter/generated_plugin_registrant.h"

struct _MyApplication {
  GtkApplication parent_instance;
  char** dart_entrypoint_arguments;
  // Runner-owned link channel. Remote Nostr command lines are delivered through
  // it instead of the gtk plugin so a link that arrives before the Dart
  // listener exists is buffered, not dropped. Link contents are never logged.
  FlMethodChannel* link_channel;
  gboolean link_ready;
  GPtrArray* pending_links;
};

G_DEFINE_TYPE(MyApplication, my_application, GTK_TYPE_APPLICATION)

static void dispatch_link(MyApplication* self, gchar* link) {
  if (self->link_ready && self->link_channel != nullptr) {
    g_autoptr(FlValue) args = fl_value_new_string(link);
    fl_method_channel_invoke_method(self->link_channel, "link", args, nullptr,
                                    nullptr, nullptr);
    g_free(link);
    return;
  }
  // Keep a bounded buffer so an unavailable listener cannot grow memory.
  if (self->pending_links->len == 20) {
    g_free(static_cast<gchar*>(g_ptr_array_index(self->pending_links, 0)));
    g_ptr_array_remove_index(self->pending_links, 0);
  }
  g_ptr_array_add(self->pending_links, link);
}

static void flush_pending_links(MyApplication* self) {
  if (!self->link_ready || self->link_channel == nullptr) {
    return;
  }
  // The array has no element free function, so free each link explicitly
  // before clearing it.
  for (guint i = 0; i < self->pending_links->len; ++i) {
    auto link = static_cast<gchar*>(self->pending_links->pdata[i]);
    g_autoptr(FlValue) args = fl_value_new_string(link);
    fl_method_channel_invoke_method(self->link_channel, "link", args, nullptr,
                                    nullptr, nullptr);
    g_free(link);
  }
  g_ptr_array_set_size(self->pending_links, 0);
}

static void link_method_call_cb(FlMethodChannel* channel,
                                FlMethodCall* method_call,
                                gpointer user_data) {
  MyApplication* self = MY_APPLICATION(user_data);
  const gchar* method = fl_method_call_get_name(method_call);
  if (strcmp(method, "ready") == 0) {
    self->link_ready = TRUE;
    g_autoptr(FlMethodResponse) response =
        FL_METHOD_RESPONSE(fl_method_success_response_new(nullptr));
    fl_method_call_respond(method_call, response, nullptr);
    // The Dart handler is installed before it reports readiness, so the
    // buffered links can be delivered immediately.
    flush_pending_links(self);
    return;
  }
  g_autoptr(FlMethodResponse) response =
      FL_METHOD_RESPONSE(fl_method_not_implemented_response_new());
  fl_method_call_respond(method_call, response, nullptr);
}

// The primary launch URI is passed to Dart as an entrypoint argument. Remote
// Nostr command lines are delivered through the readiness channel above. In
// both cases the gtk/app_links handler is skipped so a link is never delivered
// twice and never dropped before the Dart listener subscribes.
static gint handle_nostr_command(GApplication* application,
                                 GApplicationCommandLine* command_line,
                                 gpointer user_data) {
  g_auto(GStrv) args =
      g_application_command_line_get_arguments(command_line, nullptr);
  if (args && args[0] && args[1] && !args[2] &&
      g_ascii_strncasecmp(args[1], "nostr:", 6) == 0) {
    if (g_application_command_line_get_is_remote(command_line)) {
      dispatch_link(MY_APPLICATION(user_data), g_strdup(args[1]));
      // A remote link should bring the existing window forward.
      GList* windows = gtk_application_get_windows(GTK_APPLICATION(application));
      if (windows != nullptr) {
        gtk_window_present(GTK_WINDOW(windows->data));
      }
    }
    g_signal_stop_emission_by_name(application, "command-line");
  }
  return 0;
}

// Implements GApplication::activate.
static void my_application_activate(GApplication* application) {
  MyApplication* self = MY_APPLICATION(application);
  GList* windows = gtk_application_get_windows(GTK_APPLICATION(application));
  if (windows != nullptr) {
    gtk_window_present(GTK_WINDOW(windows->data));
    return;
  }
  GtkWindow* window =
      GTK_WINDOW(gtk_application_window_new(GTK_APPLICATION(application)));

  // Use a header bar when running in GNOME as this is the common style used
  // by applications and is the setup most users will be using (e.g. Ubuntu
  // desktop).
  // If running on X and not using GNOME then just use a traditional title bar
  // in case the window manager does more exotic layout, e.g. tiling.
  // If running on Wayland assume the header bar will work (may need changing
  // if future cases occur).
  gboolean use_header_bar = TRUE;
#ifdef GDK_WINDOWING_X11
  GdkScreen* screen = gtk_window_get_screen(window);
  if (GDK_IS_X11_SCREEN(screen)) {
    const gchar* wm_name = gdk_x11_screen_get_window_manager_name(screen);
    if (g_strcmp0(wm_name, "GNOME Shell") != 0) {
      use_header_bar = FALSE;
    }
  }
#endif
  if (use_header_bar) {
    GtkHeaderBar* header_bar = GTK_HEADER_BAR(gtk_header_bar_new());
    gtk_widget_show(GTK_WIDGET(header_bar));
    gtk_header_bar_set_title(header_bar, "YakiHonne");
    gtk_header_bar_set_show_close_button(header_bar, TRUE);
    gtk_window_set_titlebar(window, GTK_WIDGET(header_bar));
  } else {
    gtk_window_set_title(window, "YakiHonne");
  }

  gtk_window_set_default_size(window, 1280, 720);
  // Provisional minimum matching the existing macOS shell; validate with real
  // displays, scaling, accessibility settings and window managers.
  GdkGeometry geometry = {};
  geometry.min_width = 1153;
  geometry.min_height = 600;
  gtk_window_set_geometry_hints(window, nullptr, &geometry, GDK_HINT_MIN_SIZE);
  gtk_widget_show(GTK_WIDGET(window));

  g_autoptr(FlDartProject) project = fl_dart_project_new();
  fl_dart_project_set_dart_entrypoint_arguments(project, self->dart_entrypoint_arguments);

  FlView* view = fl_view_new(project);
  gtk_widget_show(GTK_WIDGET(view));
  gtk_container_add(GTK_CONTAINER(window), GTK_WIDGET(view));

  fl_register_plugins(FL_PLUGIN_REGISTRY(view));

  // Create the readiness channel once the engine exists. Remote links that
  // arrived before this point stay buffered until Dart reports readiness.
  g_autoptr(FlStandardMethodCodec) codec = fl_standard_method_codec_new();
  self->link_channel = fl_method_channel_new(
      fl_engine_get_binary_messenger(fl_view_get_engine(view)),
      "yakihonne/link_readiness", FL_METHOD_CODEC(codec));
  fl_method_channel_set_method_call_handler(
      self->link_channel, link_method_call_cb, self, nullptr);

  gtk_widget_grab_focus(GTK_WIDGET(view));
}

// Implements GApplication::local_command_line.
static gboolean my_application_local_command_line(GApplication* application, gchar*** arguments, int* exit_status) {
  MyApplication* self = MY_APPLICATION(application);
  // Strip out the first argument as it is the binary name.
  g_clear_pointer(&self->dart_entrypoint_arguments, g_strfreev);
  self->dart_entrypoint_arguments = g_strdupv(*arguments + 1);

  g_autoptr(GError) error = nullptr;
  if (!g_application_register(application, nullptr, &error)) {
     g_warning("Failed to register: %s", error->message);
     *exit_status = 1;
     return TRUE;
  }

  g_application_activate(application);
  *exit_status = 0;

  return FALSE;
}

// Implements GObject::dispose.
static void my_application_dispose(GObject* object) {
  MyApplication* self = MY_APPLICATION(object);
  g_clear_pointer(&self->dart_entrypoint_arguments, g_strfreev);
  if (self->link_channel != nullptr) {
    fl_method_channel_set_method_call_handler(self->link_channel, nullptr,
                                               nullptr, nullptr);
    g_clear_object(&self->link_channel);
  }
  if (self->pending_links != nullptr) {
    for (guint i = 0; i < self->pending_links->len; ++i) {
      g_free(g_ptr_array_index(self->pending_links, i));
    }
    g_ptr_array_free(self->pending_links, TRUE);
    self->pending_links = nullptr;
  }
  G_OBJECT_CLASS(my_application_parent_class)->dispose(object);
}

static void my_application_class_init(MyApplicationClass* klass) {
  G_APPLICATION_CLASS(klass)->activate = my_application_activate;
  G_APPLICATION_CLASS(klass)->local_command_line = my_application_local_command_line;
  G_OBJECT_CLASS(klass)->dispose = my_application_dispose;
}

static void my_application_init(MyApplication* self) {
  self->pending_links = g_ptr_array_new();
  g_signal_connect(self, "command-line", G_CALLBACK(handle_nostr_command), self);
}

MyApplication* my_application_new() {
  return MY_APPLICATION(g_object_new(my_application_get_type(),
                                     "application-id", APPLICATION_ID,
                                     "flags", G_APPLICATION_HANDLES_COMMAND_LINE | G_APPLICATION_HANDLES_OPEN,
                                     nullptr));
}
