///
/// Generated file. Do not edit.
///
// coverage:ignore-file
// ignore_for_file: type=lint, unused_import
// dart format off

part of 'translations.g.dart';

// Path: <root>
typedef TranslationsEn = Translations; // ignore: unused_element
class Translations implements BaseTranslations<AppLocale, Translations> {
	/// Returns the current translations of the given [context].
	///
	/// Usage:
	/// final t = Translations.of(context);
	static Translations of(BuildContext context) => InheritedLocaleData.of<AppLocale, Translations>(context).translations;

	/// You can call this constructor and build your own translation instance of this locale.
	/// Constructing via the enum [AppLocale.build] is preferred.
	Translations({Map<String, Node>? overrides, PluralResolver? cardinalResolver, PluralResolver? ordinalResolver, TranslationMetadata<AppLocale, Translations>? meta})
		: assert(overrides == null, 'Set "translation_overrides: true" in order to enable this feature.'),
		  $meta = meta ?? TranslationMetadata(
		    locale: AppLocale.en,
		    overrides: overrides ?? {},
		    cardinalResolver: cardinalResolver,
		    ordinalResolver: ordinalResolver,
		  ) {
		$meta.setFlatMapFunction(_flatMapFunction);
	}

	/// Metadata for the translations of <en>.
	@override final TranslationMetadata<AppLocale, Translations> $meta;

	/// Access flat map
	dynamic operator[](String key) => $meta.getTranslation(key);

	late final Translations _root = this; // ignore: unused_field

	Translations $copyWith({TranslationMetadata<AppLocale, Translations>? meta}) => Translations(meta: meta ?? this.$meta);

	// Translations

	/// en: 'No bookmarks list can be found, try to add one!'
	String get addNewBookmark => 'No bookmarks list can be found, try to add one!';

	/// en: 'Set a title & a description for your bookmark list.'
	String get setBookmarkTitleDescription => 'Set a title & a description for your bookmark list.';

	/// en: 'title'
	String get title => 'title';

	/// en: 'description'
	String get description => 'description';

	/// en: 'description (optional)'
	String get descriptionOptional => 'description (optional)';

	/// en: 'Bookmark lists'
	String get bookmarkLists => 'Bookmark lists';

	/// en: 'submit'
	String get submit => 'submit';

	/// en: 'Add bookmark list'
	String get addBookmarkList => 'Add bookmark list';

	/// en: 'Submit bookmark list'
	String get submitBookmarkList => 'Submit bookmark list';

	/// en: 'next'
	String get next => 'next';

	/// en: 'Save draft'
	String get saveDraft => 'Save draft';

	/// en: 'Delete draft'
	String get deleteDraft => 'Delete draft';

	/// en: 'publish'
	String get publish => 'publish';

	/// en: 'The smart widget should have atleast one component.'
	String get smHaveOneWidget => 'The smart widget should have atleast one component.';

	/// en: 'The smart widget should at least have a title'
	String get smHaveTitle => 'The smart widget should at least have a title';

	/// en: 'What's on your mind?'
	String get whatsOnYourMind => 'What\'s on your mind?';

	/// en: 'This is a sensitive content'
	String get sensitiveContent => 'This is a sensitive content';

	/// en: 'Add your topics'
	String get addYourTopics => 'Add your topics';

	/// en: 'article'
	String get article => 'article';

	/// en: 'articles'
	String get articles => 'articles';

	/// en: 'video'
	String get video => 'video';

	/// en: 'videos'
	String get videos => 'videos';

	/// en: 'curation'
	String get curation => 'curation';

	/// en: 'curations'
	String get curations => 'curations';

	/// en: 'Thumbnail preview'
	String get thumbnailPreview => 'Thumbnail preview';

	/// en: 'Select & upload a local image'
	String get selectAndUploadLocaleImage => 'Select & upload a local image';

	/// en: 'Issue occured while selecting the image.'
	String get issueOccuredSelectingImage => 'Issue occured while selecting the image.';

	/// en: 'Images upload history'
	String get imageUploadHistory => 'Images upload history';

	/// en: 'No images history has been found'
	String get noImageHistory => 'No images history has been found';

	/// en: 'cancel'
	String get cancel => 'cancel';

	/// en: 'Upload & use'
	String get uploadAndUse => 'Upload & use';

	/// en: 'Publish and remove the draft'
	String get publishRemoveDraft => 'Publish and remove the draft';

	/// en: 'Clear chat'
	String get clearChat => 'Clear chat';

	/// en: 'There are data to show from GPT.'
	String get noDataFromGpt => 'There are data to show from GPT.';

	/// en: 'Ask me something!'
	String get askMeSomething => 'Ask me something!';

	/// en: 'copy'
	String get copy => 'copy';

	/// en: 'Text successfully copied!'
	String get textSuccesfulyCopied => 'Text successfully copied!';

	/// en: 'Insert text'
	String get insertText => 'Insert text';

	/// en: 'Search {{type}} by title'
	String searchContentByTitle({required Object type}) => 'Search ${type} by title';

	/// en: 'No {{type}} can be found'
	String noContentCanBeFound({required Object type}) => 'No ${type} can be found';

	/// en: 'No {{type}} belong to this curation'
	String noContentBelongToCuration({required Object type}) => 'No ${type} belong to this curation';

	/// en: 'By {{name}}'
	String byPerson({required Object name}) => 'By ${name}';

	/// en: 'All relays'
	String get allRelays => 'All relays';

	/// en: 'My articles'
	String get myArticles => 'My articles';

	/// en: 'My videos'
	String get myVideos => 'My videos';

	/// en: 'Curation type'
	String get curationType => 'Curation type';

	/// en: 'update'
	String get update => 'update';

	/// en: 'Make sure to set a valid invoice or lnurl'
	String get invalidInvoiceLnurl => 'Make sure to set a valid invoice or lnurl';

	/// en: 'Make sure to add a valid url'
	String get addValidUrl => 'Make sure to add a valid url';

	/// en: 'Layout customization'
	String get layoutCustomization => 'Layout customization';

	/// en: 'Duolayout'
	String get duoLayout => 'Duolayout';

	/// en: 'MonoLayout'
	String get monoLayout => 'MonoLayout';

	/// en: 'warning'
	String get warning => 'warning';

	/// en: 'You're switching to a mono layout whilst having elements on both sides, this will erase the container content, do you wish to proceed?'
	String get switchToMonolayout => 'You\'re switching to a mono layout whilst having elements on both sides, this will erase the container content, do you wish to proceed?';

	/// en: 'erase'
	String get erase => 'erase';

	/// en: 'Text customization'
	String get textCustomization => 'Text customization';

	/// en: 'Write your text'
	String get writeYourText => 'Write your text';

	/// en: 'size'
	String get size => 'size';

	/// en: 'weight'
	String get weight => 'weight';

	/// en: 'color'
	String get color => 'color';

	/// en: 'Video customization'
	String get videoCustomization => 'Video customization';

	/// en: 'Video url'
	String get videoUrl => 'Video url';

	/// en: 'Zap poll customization'
	String get zapPollCustomization => 'Zap poll customization';

	/// en: 'Content text color'
	String get contentTextColor => 'Content text color';

	/// en: 'Option text color'
	String get optionTextColor => 'Option text color';

	/// en: 'Option background color'
	String get optionBackgroundColor => 'Option background color';

	/// en: 'Fill color'
	String get fillColor => 'Fill color';

	/// en: 'Image customization'
	String get imageCustomization => 'Image customization';

	/// en: 'Image url'
	String get imageUrl => 'Image url';

	/// en: 'Image aspect ratio'
	String get imageAspectRatio => 'Image aspect ratio';

	/// en: 'Button customization'
	String get buttonCustomization => 'Button customization';

	/// en: 'Button text'
	String get buttonText => 'Button text';

	/// en: 'type'
	String get type => 'type';

	/// en: 'Use invoice'
	String get useInvoice => 'Use invoice';

	/// en: 'invoice'
	String get invoice => 'invoice';

	/// en: 'Lightning address'
	String get lightningAddress => 'Lightning address';

	/// en: 'Select a user to zap (optional)'
	String get selectUserToZap => 'Select a user to zap (optional)';

	/// en: 'Zap poll nevent'
	String get zapPollNevent => 'Zap poll nevent';

	/// en: 'Text color'
	String get textColor => 'Text color';

	/// en: 'Button color'
	String get buttonColor => 'Button color';

	/// en: 'Url'
	String get url => 'Url';

	/// en: 'Invoice or Lightning address'
	String get invoiceOrLN => 'Invoice or Lightning address';

	/// en: 'Youtube url'
	String get youtubeUrl => 'Youtube url';

	/// en: 'Telegram Url'
	String get telegramUrl => 'Telegram Url';

	/// en: 'X url'
	String get xUrl => 'X url';

	/// en: 'Discord url'
	String get discordUrl => 'Discord url';

	/// en: 'Nostr Scheme'
	String get nostrScheme => 'Nostr Scheme';

	/// en: 'Container customization'
	String get containerCustomization => 'Container customization';

	/// en: 'Background color'
	String get backgroundColor => 'Background color';

	/// en: 'Border color'
	String get borderColor => 'Border color';

	/// en: 'value'
	String get value => 'value';

	/// en: 'Pick your component'
	String get pickYourComponent => 'Pick your component';

	/// en: 'Select the component at convience and edit it.'
	String get selectComponent => 'Select the component at convience and edit it.';

	/// en: 'text'
	String get text => 'text';

	/// en: 'image'
	String get image => 'image';

	/// en: 'button'
	String get button => 'button';

	/// en: 'Summary (Optional)'
	String get summaryOptional => 'Summary (Optional)';

	/// en: 'Smart widgets drafts'
	String get smartWidgetsDrafts => 'Smart widgets drafts';

	/// en: 'No smart widgets drafts can be found'
	String get noSmartWidget => 'No smart widgets drafts can be found';

	/// en: 'No smart widgets can be found'
	String get noSmartWidgetCanBeFound => 'No smart widgets can be found';

	/// en: 'This smart widget does not follow the agreed on convention.'
	String get smartWidgetConvention => 'This smart widget does not follow the agreed on convention.';

	/// en: 'Monolayout is required'
	String get monolayoutRequired => 'Monolayout is required';

	/// en: 'Zap poll'
	String get zapPoll => 'Zap poll';

	/// en: 'layout'
	String get layout => 'layout';

	/// en: 'container'
	String get container => 'container';

	/// en: 'edit'
	String get edit => 'edit';

	/// en: 'Move up'
	String get moveUp => 'Move up';

	/// en: 'Move down'
	String get moveDown => 'Move down';

	/// en: 'delete'
	String get delete => 'delete';

	/// en: 'Edit to add zap poll'
	String get editToAddZapPoll => 'Edit to add zap poll';

	/// en: 'options'
	String get options => 'options';

	/// en: 'Smart widget builder'
	String get smartWidgetBuilder => 'Smart widget builder';

	/// en: 'Start building and customize your smart widget to use on the Nostr network'
	String get startBuildingSmartWidget => 'Start building and customize your smart widget to use on the Nostr network';

	/// en: 'Blank widget'
	String get blankWidget => 'Blank widget';

	/// en: 'My drafts'
	String get myDrafts => 'My drafts';

	/// en: 'templates'
	String get templates => 'templates';

	/// en: 'Community polls'
	String get communityPolls => 'Community polls';

	/// en: 'My polls'
	String get myPolls => 'My polls';

	/// en: 'No polls can be found'
	String get noPollsCanBeFound => 'No polls can be found';

	/// en: 'Total: {{number}}'
	String totalNumber({required Object number}) => 'Total: ${number}';

	/// en: 'Smart widgets templates'
	String get smartWidgetsTemplates => 'Smart widgets templates';

	/// en: 'No templates can be found in this category.'
	String get noTemplatesCanBeFound => 'No templates can be found in this category.';

	/// en: 'Use template'
	String get useTemplate => 'Use template';

	/// en: 'Pick your video'
	String get pickYourVideo => 'Pick your video';

	/// en: 'You can upload, paste a link or choose a kind 1063 nevent to your video.'
	String get canUploadPastLink => 'You can upload, paste a link or choose a kind 1063 nevent to your video.';

	/// en: 'Gallery'
	String get gallery => 'Gallery';

	/// en: 'Link'
	String get link => 'Link';

	/// en: 'File sharing'
	String get fileSharing => 'File sharing';

	/// en: 'Set up your link'
	String get setUpYourLink => 'Set up your link';

	/// en: 'Set up your nevent'
	String get setUpYourNevent => 'Set up your nevent';

	/// en: 'Paste your link and submit it'
	String get pasteYourLink => 'Paste your link and submit it';

	/// en: 'Paste your kind 1063 nevent and submit it'
	String get pasteKind1063 => 'Paste your kind 1063 nevent and submit it';

	/// en: 'Add a proper url/nevent'
	String get addUrlNevent => 'Add a proper url/nevent';

	/// en: 'nevent'
	String get nevent => 'nevent';

	/// en: 'Add a proper url/nevent'
	String get addProperUrlNevent => 'Add a proper url/nevent';

	/// en: 'Horizontal video'
	String get horizontalVideo => 'Horizontal video';

	/// en: 'Preview'
	String get preview => 'Preview';

	/// en: 'Write a summary'
	String get writeSummary => 'Write a summary';

	/// en: 'Upload image'
	String get uploadImage => 'Upload image';

	/// en: 'Add to curation'
	String get addToCuration => 'Add to curation';

	/// en: 'Submit curation'
	String get submitCuration => 'Submit curation';

	/// en: 'Select a valid url image.'
	String get selectValidUrlImage => 'Select a valid url image.';

	/// en: 'No curations have been found. Try to create one in order to be able to add content to it.'
	String get noCurationsFound => 'No curations have been found. Try to create one in order to be able to add content to it.';

	/// en: '{{number}} available article(s)'
	String availableArticles({required Object number}) => '${number} available article(s)';

	/// en: '{{number}} available video(s)'
	String availableVideos({required Object number}) => '${number} available video(s)';

	/// en: '{{number}} article(s)'
	String articlesNum({required Object number}) => '${number} article(s)';

	/// en: '{{number}} video(s)'
	String videosNum({required Object number}) => '${number} video(s)';

	/// en: 'Articles available on this curation'
	String get articlesAvailableCuration => 'Articles available on this curation';

	/// en: 'Videos available on this curation'
	String get videosAvailableCuration => 'Videos available on this curation';

	/// en: 'Article has been added to your curation.'
	String get articleAddedCuration => 'Article has been added to your curation.';

	/// en: 'Video has been added to your curation.'
	String get videoAddedCuration => 'Video has been added to your curation.';

	/// en: 'Make sure to add a valid title for this curation'
	String get validTitleCuration => 'Make sure to add a valid title for this curation';

	/// en: 'Make sure to add a valid description for this curation'
	String get validDescriptionCuration => 'Make sure to add a valid description for this curation';

	/// en: 'Make sure to add a valid image for this curation'
	String get validImageCuration => 'Make sure to add a valid image for this curation';

	/// en: 'Add curation'
	String get addCuration => 'Add curation';

	/// en: 'Posted by'
	String get postedBy => 'Posted by';

	/// en: 'follow'
	String get follow => 'follow';

	/// en: 'unfollow'
	String get unfollow => 'unfollow';

	/// en: 'posted from'
	String get postedFrom => 'posted from';

	/// en: 'No title'
	String get noTitle => 'No title';

	/// en: '{{number}} item(s)'
	String itemsNumber({required Object number}) => '${number} item(s)';

	/// en: 'No articles on this curation have been found'
	String get noArticlesInCuration => 'No articles on this curation have been found';

	/// en: 'No videos on this curation have been found'
	String get noVideosInCuration => 'No videos on this curation have been found';

	/// en: 'add'
	String get add => 'add';

	/// en: 'No booksmarks list were found, try to add one!'
	String get noBookmarksListFound => 'No booksmarks list were found, try to add one!';

	/// en: 'Delete bookmark list'
	String get deleteBookmarkList => 'Delete bookmark list';

	/// en: 'You're about to delete this bookmarks list, do you wish to proceed?'
	String get confirmDeleteBookmarkList => 'You\'re about to delete this bookmarks list, do you wish to proceed?';

	/// en: 'Bookmarks'
	String get bookmarks => 'Bookmarks';

	/// en: '{{number}} bookmarks lists'
	String bookmarksListCount({required Object number}) => '${number} bookmarks lists';

	/// en: 'No description'
	String get noDescription => 'No description';

	/// en: 'Edited on: {{date}}'
	String editedOn({required Object date}) => 'Edited on: ${date}';

	/// en: 'Published on: {{date}}'
	String publishedOn({required Object date}) => 'Published on: ${date}';

	/// en: 'Published on'
	String get publishedOnText => 'Published on';

	/// en: 'Last updated on: {{date}}'
	String lastUpdatedOn({required Object date}) => 'Last updated on: ${date}';

	/// en: 'Joined on: {{date}}'
	String joinedOn({required Object date}) => 'Joined on: ${date}';

	/// en: 'list'
	String get list => 'list';

	/// en: 'No elements can be found in bookmarks list'
	String get noElementsInBookmarks => 'No elements can be found in bookmarks list';

	/// en: 'draft'
	String get draft => 'draft';

	/// en: 'note'
	String get note => 'note';

	/// en: 'notes'
	String get notes => 'notes';

	/// en: 'Smart Widget'
	String get smartWidget => 'Smart Widget';

	/// en: 'widgets'
	String get widgets => 'widgets';

	/// en: 'Post note'
	String get postNote => 'Post note';

	/// en: 'Post article'
	String get postArticle => 'Post article';

	/// en: 'Post curation'
	String get postCuration => 'Post curation';

	/// en: 'Post video'
	String get postVideo => 'Post video';

	/// en: 'Post smart widget'
	String get postSmartWidget => 'Post smart widget';

	/// en: 'ongoing'
	String get ongoing => 'ongoing';

	/// en: '{{number}} components in this widget'
	String componentsSMCount({required Object number}) => '${number} components in this widget';

	/// en: 'share'
	String get share => 'share';

	/// en: 'Copy note ID'
	String get copyNoteId => 'Copy note ID';

	/// en: 'Note id was copied! 👏'
	String get noteIdCopied => 'Note id was copied! 👏';

	/// en: 'You're about to delete this draft, do you wish to proceed?'
	String get confirmDeleteDraft => 'You\'re about to delete this draft, do you wish to proceed?';

	/// en: 'reposted'
	String get reposted => 'reposted';

	/// en: 'Post in note'
	String get postInNote => 'Post in note';

	/// en: 'clone'
	String get clone => 'clone';

	/// en: 'Check validity'
	String get checkValidity => 'Check validity';

	/// en: 'copy naddr'
	String get copyNaddr => 'copy naddr';

	/// en: 'Delete {{type}}'
	String deleteContent({required Object type}) => 'Delete ${type}';

	/// en: 'You're about to delete this {{type}}, do you wish to proceed?'
	String confirmDeleteContent({required Object type}) => 'You\'re about to delete this ${type}, do you wish to proceed?';

	/// en: 'Home'
	String get home => 'Home';

	/// en: 'Followings'
	String get followings => 'Followings';

	/// en: 'Followers'
	String get followers => 'Followers';

	/// en: 'replies'
	String get replies => 'replies';

	/// en: 'Zaps received'
	String get zapReceived => 'Zaps received';

	/// en: 'Total amount'
	String get totalAmount => 'Total amount';

	/// en: 'Zaps sent'
	String get zapSent => 'Zaps sent';

	/// en: 'latest'
	String get latest => 'latest';

	/// en: 'saved'
	String get saved => 'saved';

	/// en: 'See all'
	String get seeAll => 'See all';

	/// en: 'Popular notes'
	String get popularNotes => 'Popular notes';

	/// en: 'Get started now'
	String get getStartedNow => 'Get started now';

	/// en: 'Expand the world by adding what fascinates you. Select your interests and let the journey begins'
	String get expandWorld => 'Expand the world by adding what fascinates you. Select your interests and let the journey begins';

	/// en: 'Add interests'
	String get addInterests => 'Add interests';

	/// en: 'Manage interests'
	String get manageInterests => 'Manage interests';

	/// en: 'interests'
	String get interests => 'interests';

	/// en: 'YakiHonne's improvements'
	String get yakihonneImprovements => 'YakiHonne\'s improvements';

	/// en: 'YakiHonne's note'
	String get yakihonneNote => 'YakiHonne\'s note';

	/// en: 'Our app guarantees the utmost privacy by securely storing sensitive data locally on users' devices, employing stringent encryption. Rest assured, we uphold a strict no-sharing policy, ensuring that sensitive information remains confidential and never leaves the user's device.'
	String get privacyNote => 'Our app guarantees the utmost privacy by securely storing sensitive data locally on users\' devices, employing stringent encryption. Rest assured, we uphold a strict no-sharing policy, ensuring that sensitive information remains confidential and never leaves the user\'s device.';

	/// en: 'Pick your media'
	String get pickYourMedia => 'Pick your media';

	/// en: 'You can upload and send media right after your selection or taking them.'
	String get uploadSendMedia => 'You can upload and send media right after your selection or taking them.';

	/// en: 'No messages to be displayed.'
	String get noMessagesToDisplay => 'No messages to be displayed.';

	/// en: 'For more security & privacy, consider enabling Secure DMs.'
	String get enableSecureDmsMessage => 'For more security & privacy, consider enabling Secure DMs.';

	/// en: 'Replying to: {{name}}'
	String replyingTo({required Object name}) => 'Replying to: ${name}';

	/// en: 'Write a message'
	String get writeYourMessage => 'Write a message';

	/// en: 'zap'
	String get zap => 'zap';

	/// en: 'Disable Secure DMs'
	String get disableSecureDms => 'Disable Secure DMs';

	/// en: 'Enable Secure DMs'
	String get enableSecureDms => 'Enable Secure DMs';

	/// en: 'You are no longer using Secure Dms'
	String get notUsingSecureDms => 'You are no longer using Secure Dms';

	/// en: 'You are now using Secure Dms'
	String get usingSecureDms => 'You are now using Secure Dms';

	/// en: 'mute'
	String get mute => 'mute';

	/// en: 'unmute'
	String get unmute => 'unmute';

	/// en: 'Mute user'
	String get muteUser => 'Mute user';

	/// en: 'Unmute user'
	String get unmuteUser => 'Unmute user';

	/// en: 'Your are about to mute {{name}}, do you wish to proceed?'
	String muteUserDesc({required Object name}) => 'Your are about to mute ${name}, do you wish to proceed?';

	/// en: 'Your are about to unmute {{name}}, do you wish to proceed?'
	String unmuteUserDesc({required Object name}) => 'Your are about to unmute ${name}, do you wish to proceed?';

	/// en: 'Message successfully copied!'
	String get messageCopied => 'Message successfully copied!';

	/// en: 'Message has not been decrypted yet!'
	String get messageNotDecrypted => 'Message has not been decrypted yet!';

	/// en: 'reply'
	String get reply => 'reply';

	/// en: 'New message'
	String get newMessage => 'New message';

	/// en: 'Search by name, npub, nprofile'
	String get searchNameNpub => 'Search by name, npub, nprofile';

	/// en: 'Search by username'
	String get searchByUserName => 'Search by username';

	/// en: 'Known'
	String get known => 'Known';

	/// en: 'Unknown'
	String get unknown => 'Unknown';

	/// en: 'No messages can be found'
	String get noMessageCanBeFound => 'No messages can be found';

	/// en: 'You: '
	String get you => 'You: ';

	/// en: 'Decrypting message'
	String get decrMessage => 'Decrypting message';

	/// en: 'gifs'
	String get gifs => 'gifs';

	/// en: 'stickers'
	String get stickers => 'stickers';

	/// en: 'Customize your feed'
	String get customizeYourFeed => 'Customize your feed';

	/// en: 'Feed options'
	String get feedOptions => 'Feed options';

	/// en: 'recent'
	String get recent => 'recent';

	/// en: 'Recent with replies'
	String get recentWithReplies => 'Recent with replies';

	/// en: 'explore'
	String get explore => 'explore';

	/// en: 'following'
	String get following => 'following';

	/// en: 'trending'
	String get trending => 'trending';

	/// en: 'highlights'
	String get highlights => 'highlights';

	/// en: 'paid'
	String get paid => 'paid';

	/// en: 'others'
	String get others => 'others';

	/// en: 'Suggestions box'
	String get suggestionsBox => 'Suggestions box';

	/// en: 'Show suggestions'
	String get showSuggestions => 'Show suggestions';

	/// en: 'Show suggested people to follow'
	String get showSuggestedPeople => 'Show suggested people to follow';

	/// en: 'Show articles/notes suggestions'
	String get showArticlesNotesSuggestions => 'Show articles/notes suggestions';

	/// en: 'Show suggested interests'
	String get showSuggestedInterests => 'Show suggested interests';

	/// en: '{{time}}m read'
	String readTime({required Object time}) => '${time}m read';

	/// en: 'watch now'
	String get watchNow => 'watch now';

	/// en: 'bookmark'
	String get bookmark => 'bookmark';

	/// en: 'Suggestions'
	String get suggestions => 'Suggestions';

	/// en: 'Hide suggestions'
	String get hideSuggestions => 'Hide suggestions';

	/// en: 'Enjoy the experience of owning your own data!'
	String get enjoyExpOwnData => 'Enjoy the experience of owning\nyour own data!';

	/// en: 'Sign in'
	String get signIn => 'Sign in';

	/// en: 'Create account'
	String get createAccount => 'Create account';

	/// en: 'By continuing you agree with our '
	String get byContinuing => 'By continuing you agree with our\n';

	/// en: 'End User Licence Agreement (EULA)'
	String get eula => 'End User Licence Agreement (EULA)';

	/// en: 'Continue as a guest'
	String get continueAsGuest => 'Continue as a guest';

	/// en: 'Hey, Welcome Back'
	String get heyWelcomeBack => 'Hey,\nWelcome\nBack';

	/// en: 'npub, nsec or hex'
	String get npubNsecHex => 'npub, nsec or hex';

	/// en: 'Use Amber'
	String get useAmber => 'Use Amber';

	/// en: 'Set a valid key'
	String get setValidKey => 'Set a valid key';

	/// en: 'Paste your key'
	String get pasteYourKey => 'Paste your key';

	/// en: 'Tailor your experience by selecting your top interests'
	String get taylorExperienceInterests => 'Tailor your experience by selecting your top interests';

	/// en: '+{{number}} people'
	String peopleCountPlus({required Object number}) => '+${number} people';

	/// en: 'Follow all'
	String get followAll => 'Follow all';

	/// en: 'Unfollow all'
	String get unfollowAll => 'Unfollow all';

	/// en: 'details'
	String get details => 'details';

	/// en: 'Share a glimpse of you, in words that feel true.'
	String get shareGlimps => 'Share a glimpse of you, in words that feel true.';

	/// en: 'Add cover'
	String get addCover => 'Add cover';

	/// en: 'Edit cover'
	String get editCover => 'Edit cover';

	/// en: 'Your name'
	String get yourName => 'Your name';

	/// en: 'Set a proper name'
	String get setProperName => 'Set a proper name';

	/// en: 'About you'
	String get aboutYou => 'About you';

	/// en: 'You can find your account secret key in your settings. This key is essential to secure access to your account. Please keep it safe and private.'
	String get secKeyDesc => 'You can find your account secret key in your settings. This key is essential to secure access to your account. Please keep it safe and private.';

	/// en: 'You can find your account secret key and wallet connection secret in your settings. These keys are essential to secure access to your account and wallet. Please keep them safe and private.'
	String get secKeyWalletDesc => 'You can find your account secret key and wallet connection secret in your settings. These keys are essential to secure access to your account and wallet. Please keep them safe and private.';

	/// en: 'Initializing account...'
	String get initializingAccount => 'Initializing account...';

	/// en: 'Let's get started!'
	String get letsGetStarted => 'Let\'s get started!';

	/// en: 'Don't have a wallet?'
	String get dontHaveWallet => 'Don\'t have a wallet?';

	/// en: 'Create a wallet to send and receive sats'
	String get createWalletSendRecSats => 'Create a wallet to send and receive sats';

	/// en: 'Create wallet'
	String get createWallet => 'Create wallet';

	/// en: 'You're all set'
	String get youreAllSet => 'You\'re all set';

	/// en: 'dashboard'
	String get dashboard => 'dashboard';

	/// en: 'Verify notes'
	String get verifyNotes => 'Verify notes';

	/// en: 'settings'
	String get settings => 'settings';

	/// en: 'Manage accounts'
	String get manageAccounts => 'Manage accounts';

	/// en: 'Login'
	String get login => 'Login';

	/// en: 'Switch accounts'
	String get switchAccounts => 'Switch accounts';

	/// en: 'Add account'
	String get addAccount => 'Add account';

	/// en: 'Logout all accounts'
	String get logoutAllAccounts => 'Logout all accounts';

	/// en: 'search'
	String get search => 'search';

	/// en: 'Smart widgets'
	String get smartWidgets => 'Smart widgets';

	/// en: 'notifications'
	String get notifications => 'notifications';

	/// en: 'inbox'
	String get inbox => 'inbox';

	/// en: 'discover'
	String get discover => 'discover';

	/// en: 'wallet'
	String get wallet => 'wallet';

	/// en: 'Public key'
	String get publicKey => 'Public key';

	/// en: 'Profile link'
	String get profileLink => 'Profile link';

	/// en: 'Profile link was copied! 👏'
	String get profileCopied => 'Profile link was copied! 👏';

	/// en: 'Public key was copied! 👏'
	String get publicKeyCopied => 'Public key was copied! 👏';

	/// en: 'lightning address was copied! 👏'
	String get lnCopied => 'lightning address was copied! 👏';

	/// en: 'Scan QR code'
	String get scanQrCode => 'Scan QR code';

	/// en: 'View QR code'
	String get viewQrCode => 'View QR code';

	/// en: 'Copy pubkey'
	String get copyNpub => 'Copy pubkey';

	/// en: 'Visit profile'
	String get visitProfile => 'Visit profile';

	/// en: 'Follow me on Nostr'
	String get followMeOnNostr => 'Follow me on Nostr';

	/// en: 'close'
	String get close => 'close';

	/// en: 'Loading previous post(s)...'
	String get loadingPreviousPosts => 'Loading previous post(s)...';

	/// en: 'No replies for this note can be found'
	String get noRepliesDesc => 'No replies for this note can be found';

	/// en: 'thread'
	String get thread => 'thread';

	/// en: 'all'
	String get all => 'all';

	/// en: 'mentions'
	String get mentions => 'mentions';

	/// en: 'zaps'
	String get zaps => 'zaps';

	/// en: 'No notifications can be found'
	String get noNotificationCanBeFound => 'No notifications can be found';

	/// en: '1- Submit your content for attestation'
	String get consumablePointsPerks1 => '1- Submit your content for attestation';

	/// en: '2- Redeem points to publish paid notes'
	String get consumablePointsPerks2 => '2- Redeem points to publish paid notes';

	/// en: '3- Redeem points for SATs (Random thresholds are selected and you will be notified whenever redemption is available)'
	String get consumablePointsPerks3 => '3- Redeem points for SATs (Random thresholds are selected and you will be notified whenever redemption is available)';

	/// en: 'YakiHonne's Consumable points'
	String get yakihonneConsPoints => 'YakiHonne\'s Consumable points';

	/// en: 'Soon users will be able to use the consumable points in the following set of activities:'
	String get soonUsers => 'Soon users will be able to use the consumable points in the following set of activities:';

	/// en: 'Start earning and make the most of your Yaki Points! 🎉'
	String get startEarningPoints => 'Start earning and make the most of your Yaki Points! 🎉';

	/// en: 'Got it!'
	String get gotIt => 'Got it!';

	/// en: 'Engagement chart'
	String get engagementChart => 'Engagement chart';

	/// en: 'Last gained: {{date}}'
	String lastGained({required Object date}) => 'Last gained: ${date}';

	/// en: 'Attempts remained '
	String get attemptsRemained => 'Attempts remained ';

	/// en: 'Congratulations'
	String get congratulations => 'Congratulations';

	/// en: 'You have been rewarded {{number}} xp for the following actions, be active and earn rewards!'
	String congratsDesc({required Object number}) => 'You have been rewarded ${number} xp for the following actions, be active and earn rewards!';

	/// en: 'YakiHonne's Chest!'
	String get yakihonneChest => 'YakiHonne\'s Chest!';

	/// en: 'No, I'm good'
	String get noImGood => 'No, I\'m good';

	/// en: 'Points'
	String get points => 'Points';

	/// en: 'Unlocked'
	String get unlocked => 'Unlocked';

	/// en: 'Locked'
	String get locked => 'Locked';

	/// en: 'What's this?'
	String get whatsThis => 'What\'s this?';

	/// en: 'Level {{number}}'
	String levelNumber({required Object number}) => 'Level ${number}';

	/// en: 'Points system'
	String get pointsSystem => 'Points system';

	/// en: 'One time rewards'
	String get oneTimeRewards => 'One time rewards';

	/// en: 'Repeated rewards'
	String get repeatedRewards => 'Repeated rewards';

	/// en: 'Consumable points'
	String get consumablePoints => 'Consumable points';

	/// en: '{{number}} remaining'
	String pointsRemaining({required Object number}) => '${number} remaining';

	/// en: 'Gain'
	String get gain => 'Gain';

	/// en: 'for {{name}}'
	String forName({required Object name}) => 'for ${name}';

	/// en: 'min'
	String get min => 'min';

	/// en: '{{number}} levels required'
	String levelsRequiredNum({required Object number}) => '${number} levels required';

	/// en: 'See more'
	String get seeMore => 'See more';

	/// en: 'Delete cover picture!'
	String get deleteCoverPic => 'Delete cover picture!';

	/// en: 'You're about to delete your cover picture, do you wish to proceed?'
	String get deleteCoverPicDesc => 'You\'re about to delete your cover picture, do you wish to proceed?';

	/// en: 'Edit profile'
	String get editProfile => 'Edit profile';

	/// en: 'Uploading image...'
	String get uploadingImage => 'Uploading image...';

	/// en: 'Update Profile'
	String get updateProfile => 'Update Profile';

	/// en: 'User name'
	String get userName => 'User name';

	/// en: 'Display name'
	String get displayName => 'Display name';

	/// en: 'Your display name'
	String get yourDisplayName => 'Your display name';

	/// en: 'Write something about you!'
	String get writeSomethingAboutYou => 'Write something about you!';

	/// en: 'Website'
	String get website => 'Website';

	/// en: 'Your website'
	String get yourWebsite => 'Your website';

	/// en: 'Verified Nostr Address (NIP 05)'
	String get verifyNip05 => 'Verified Nostr Address (NIP 05)';

	/// en: 'Enter your NIP-05 address'
	String get enterNip05 => 'Enter your NIP-05 address';

	/// en: 'Enter your address LUD-06 or LUD-16'
	String get enterLn => 'Enter your address LUD-06 or LUD-16';

	/// en: 'Less'
	String get less => 'Less';

	/// en: 'More'
	String get more => 'More';

	/// en: 'Picture url'
	String get pictureUrl => 'Picture url';

	/// en: 'Cover url'
	String get coverUrl => 'Cover url';

	/// en: 'Enter your picture url'
	String get enterPictureUrl => 'Enter your picture url';

	/// en: 'Enter your cover url'
	String get enterCoverUrl => 'Enter your cover url';

	/// en: '{{name}} has no articles'
	String userNoArticles({required Object name}) => '${name} has no articles';

	/// en: '{{name}} has no curations'
	String userNoCurations({required Object name}) => '${name} has no curations';

	/// en: '{{name}} has no notes'
	String userNoNotes({required Object name}) => '${name} has no notes';

	/// en: '{{name}} has no videos'
	String userNoVideos({required Object name}) => '${name} has no videos';

	/// en: 'Loading followings'
	String get loadingFollowings => 'Loading followings';

	/// en: 'loading followers'
	String get loadingFollowers => 'loading followers';

	/// en: '{{number}} followers'
	String followersNum({required Object number}) => '${number} followers';

	/// en: 'Not followed by anyone you follow.'
	String get notFollowedByAnyoneYouFollow => 'Not followed by anyone you follow.';

	/// en: 'mutual(s)'
	String get mutuals => 'mutual(s)';

	/// en: '+ {{number}} mutual(s)'
	String mutualsNum({required Object number}) => '+ ${number} mutual(s)';

	/// en: 'Follows you'
	String get followsYou => 'Follows you';

	/// en: 'User name was successfully copied!'
	String get userNameCopied => 'User name was successfully copied!';

	/// en: 'Profile recommended relays - {{number}}'
	String profileRelays({required Object number}) => 'Profile recommended relays - ${number}';

	/// en: 'No relays for this user were found.'
	String get noUserRelays => 'No relays for this user were found.';

	/// en: '{{name}} has no smart widgets'
	String userNoSmartWidgets({required Object name}) => '${name} has no smart widgets';

	/// en: 'Ratings of Not Helpful on notes that ended up with a status of Helpful'
	String get un1 => 'Ratings of Not Helpful on notes that ended up with a status of Helpful';

	/// en: 'These ratings are counted twice because they often indicate support for notes that others deemed helpful.'
	String get un1Desc => 'These ratings are counted twice because they often indicate support for notes that others deemed helpful.';

	/// en: 'Notes with ongoing ratings'
	String get un2 => 'Notes with ongoing ratings';

	/// en: 'Ratings on notes that don't currently have a status of Helpful or Not Helpful'
	String get un2Desc => 'Ratings on notes that don\'t currently have a status of Helpful or Not Helpful';

	/// en: 'Notes that earned the status of Helpful'
	String get unTextW1 => 'Notes that earned the status of Helpful';

	/// en: 'These notes are now showing to everyone who sees the post, adding context and helping keep people informed.'
	String get unTextW1Desc => 'These notes are now showing to everyone who sees the post, adding context and helping keep people informed.';

	/// en: 'Ratings that helped a note earn the status of Helpful'
	String get unTextR1 => 'Ratings that helped a note earn the status of Helpful';

	/// en: 'These ratings identified Helpful notes that gets shown to everyone, adding context and helping keep people informed.'
	String get unTextR1Desc => 'These ratings identified Helpful notes that gets shown to everyone, adding context and helping keep people informed.';

	/// en: 'Notes that reached the status of Not Helpful'
	String get unTextW2 => 'Notes that reached the status of Not Helpful';

	/// en: 'These notes have been rated Not Helpful by enough contributors, including those who sometimes disagree in their past ratings.'
	String get unTextW2Desc => 'These notes have been rated Not Helpful by enough contributors, including those who sometimes disagree in their past ratings.';

	/// en: 'Ratings that helped a note earn the status of Not Helpful'
	String get unTextR2 => 'Ratings that helped a note earn the status of Not Helpful';

	/// en: 'These ratings improve Verified Notes by giving feedback to note authors, and allowing contributors to focus on the most promising notes'
	String get unTextR2Desc => 'These ratings improve Verified Notes by giving feedback to note authors, and allowing contributors to focus on the most promising notes';

	/// en: 'Notes that need more ratings'
	String get unTextW3 => 'Notes that need more ratings';

	/// en: 'Notes that don't yet have a status of Helpful or Not Helpful.'
	String get unTextW3Desc => 'Notes that don\'t yet have a status of Helpful or Not Helpful.';

	/// en: 'Ratings of Not Helpful on notes that ended up with a status of Helpful'
	String get unTextR3 => 'Ratings of Not Helpful on notes that ended up with a status of Helpful';

	/// en: 'Don't worry, everyone gets some of these! These ratings are common and can lead to status changes if enough people agree that a 'Helpful' note isn't sufficiently helpful.'
	String get unTextR3Desc => 'Don\'t worry, everyone gets some of these! These ratings are common and can lead to status changes if enough people agree that a \'Helpful\' note isn\'t sufficiently helpful.';

	/// en: 'refresh'
	String get refresh => 'refresh';

	/// en: 'User's impact'
	String get userImpact => 'User\'s impact';

	/// en: 'User's relays'
	String get userRelays => 'User\'s relays';

	/// en: 'rewards'
	String get rewards => 'rewards';

	/// en: 'You have no rewards, interact with or write verified notes in order to obtain them.'
	String get noRewards => 'You have no rewards, interact with or write verified notes in order to obtain them.';

	/// en: 'On {{date}}'
	String onDate({required Object date}) => 'On ${date}';

	/// en: 'You have rated'
	String get youHaveRated => 'You have rated';

	/// en: 'the following note:'
	String get theFollowingNote => 'the following note:';

	/// en: 'You have left a note on this paid note:'
	String get youHaveLeftNote => 'You have left a note on this paid note:';

	/// en: 'Paid note loading'
	String get paidNoteLoading => 'Paid note loading';

	/// en: 'Your following note just got sealed:'
	String get yourNoteSealed => 'Your following note just got sealed:';

	/// en: 'You have rated the following note which got sealed:'
	String get ratedNoteSealed => 'You have rated the following note which got sealed:';

	/// en: 'Claim in {{time}}'
	String claimTime({required Object time}) => 'Claim in ${time}';

	/// en: 'Claim'
	String get claim => 'Claim';

	/// en: 'Request in progress'
	String get requestInProgress => 'Request in progress';

	/// en: 'Granted'
	String get granted => 'Granted';

	/// en: 'Interested'
	String get interested => 'Interested';

	/// en: 'Not interested'
	String get notInterested => 'Not interested';

	/// en: 'No result for this keyword'
	String get noResKeyword => 'No result for this keyword';

	/// en: 'No results have been found using this keyword, try to use another keywords in order to get a better results.'
	String get noResKeywordDesc => 'No results have been found using this keyword, try to use another keywords in order to get a better results.';

	/// en: 'Start searching for people'
	String get startSearchPeople => 'Start searching for people';

	/// en: 'Start searching for content'
	String get startSearchContent => 'Start searching for content';

	/// en: 'Keys'
	String get keys => 'Keys';

	/// en: 'My public key'
	String get myPublicKey => 'My public key';

	/// en: 'My secret key'
	String get mySecretKey => 'My secret key';

	/// en: 'show'
	String get show => 'show';

	/// en: 'Show secret key!'
	String get showSecret => 'Show secret key!';

	/// en: 'Make sure to keep it safe as it gives a full access to your account.'
	String get showSecretDesc => 'Make sure to keep it safe as it gives a full access to your account.';

	/// en: 'Using an external signer'
	String get usingExternalSign => 'Using an external signer';

	/// en: 'You are using an external signer'
	String get usingExternalSignDesc => 'You are using an external signer';

	/// en: 'Private key was copied! 👏'
	String get privKeyCopied => 'Private key was copied! 👏';

	/// en: 'Mute list'
	String get muteList => 'Mute list';

	/// en: 'No muted users have been found.'
	String get noMutedUserFound => 'No muted users have been found.';

	/// en: 'Search relay'
	String get searchRelay => 'Search relay';

	/// en: 'Delete account'
	String get deleteAccount => 'Delete account';

	/// en: 'Clear app cache'
	String get clearAppCache => 'Clear app cache';

	/// en: 'You are about to clear the app cache, do you wish to proceed?'
	String get clearAppCacheDesc => 'You are about to clear the app cache, do you wish to proceed?';

	/// en: 'clear'
	String get clear => 'clear';

	/// en: 'Font Size'
	String get fontSize => 'Font Size';

	/// en: 'App theme'
	String get appTheme => 'App theme';

	/// en: 'Content moderation'
	String get contentModeration => 'Content moderation';

	/// en: 'Media uploader'
	String get mediaUploader => 'Media uploader';

	/// en: 'Secure direct messaging'
	String get secureDirectMessaging => 'Secure direct messaging';

	/// en: 'Customization'
	String get customization => 'Customization';

	/// en: 'Home feed customization'
	String get hfCustomization => 'Home feed customization';

	/// en: 'New post long press gesture'
	String get newPostGesture => 'New post long press gesture';

	/// en: 'Profile preview'
	String get profilePreview => 'Profile preview';

	/// en: 'Relay settings {{number}}'
	String relaySettings({required Object number}) => 'Relay settings ${number}';

	/// en: 'YakiHonne'
	String get yakihonne => 'YakiHonne';

	/// en: 'wallets'
	String get wallets => 'wallets';

	/// en: 'Add wallet'
	String get addWallet => 'Add wallet';

	/// en: 'External wallet'
	String get externalWallet => 'External wallet';

	/// en: 'Yaki chest'
	String get yakiChest => 'Yaki chest';

	/// en: 'Connected'
	String get connected => 'Connected';

	/// en: 'Connect'
	String get connect => 'Connect';

	/// en: 'Owner'
	String get owner => 'Owner';

	/// en: 'Contact'
	String get contact => 'Contact';

	/// en: 'Software'
	String get software => 'Software';

	/// en: 'Version'
	String get version => 'Version';

	/// en: 'Supported Nips'
	String get supportedNips => 'Supported Nips';

	/// en: 'Instant connect to relay'
	String get instantConntect => 'Instant connect to relay';

	/// en: 'Invalid relay url'
	String get invalidRelayUrl => 'Invalid relay url';

	/// en: 'Relays'
	String get relays => 'Relays';

	/// en: 'Read only'
	String get readOnly => 'Read only';

	/// en: 'Write only'
	String get writeOnly => 'Write only';

	/// en: 'Read/Write'
	String get readWrite => 'Read/Write';

	/// en: 'Default'
	String get defaultKey => 'Default';

	/// en: 'View profile'
	String get viewProfile => 'View profile';

	/// en: 'Appearance'
	String get appearance => 'Appearance';

	/// en: 'Untitled'
	String get untitled => 'Untitled';

	/// en: 'Smart widget checker'
	String get smartWidgetChecker => 'Smart widget checker';

	/// en: 'naddr'
	String get naddr => 'naddr';

	/// en: 'No components can be displayed'
	String get noComponentsDisplayed => 'No components can be displayed';

	/// en: 'metadata'
	String get metadata => 'metadata';

	/// en: 'Created at'
	String get createdAt => 'Created at';

	/// en: 'Identifier'
	String get identifier => 'Identifier';

	/// en: 'Enter a smart widget naddr to check for its validity.'
	String get enterSMaddr => 'Enter a smart widget naddr to check for its validity.';

	/// en: 'Could not find smart widget with such address'
	String get notFindSMwithAddr => 'Could not find smart widget with such address';

	/// en: 'Unable to open url'
	String get unableToOpenUrl => 'Unable to open url';

	/// en: 'You should vote to be able to see stats'
	String get voteToSeeStats => 'You should vote to be able to see stats';

	/// en: 'Votes by zaps'
	String get votesByZaps => 'Votes by zaps';

	/// en: 'Votes by users'
	String get votesByUsers => 'Votes by users';

	/// en: 'You have already voted on this poll'
	String get alreadyVoted => 'You have already voted on this poll';

	/// en: 'User cannot be found'
	String get userCannotBeFound => 'User cannot be found';

	/// en: 'Votes: {{number}}'
	String votesNumber({required Object number}) => 'Votes: ${number}';

	/// en: 'Vote is required to display stats.'
	String get voteRequired => 'Vote is required to display stats.';

	/// en: 'Show stats'
	String get showStats => 'Show stats';

	/// en: 'Closes at: {{date}}'
	String pollClosesAt({required Object date}) => 'Closes at: ${date}';

	/// en: 'Closed at: {{date}}'
	String pollClosedAt({required Object date}) => 'Closed at: ${date}';

	/// en: 'Check a smart widget'
	String get checkSmartWidget => 'Check a smart widget';

	/// en: 'Empty verified note content!'
	String get emptyVerifiedNote => 'Empty verified note content!';

	/// en: 'Post'
	String get post => 'Post';

	/// en: 'See anything you want to improve?'
	String get seeAnything => 'See anything you want to improve?';

	/// en: 'Write a note'
	String get writeNote => 'Write a note';

	/// en: 'What do you think about this ?'
	String get whatThinkThis => 'What do you think about this ?';

	/// en: 'Source (recommended)'
	String get sourceRecommended => 'Source (recommended)';

	/// en: 'You find this paid note correct.'
	String get findPaidNoteCorrect => 'You find this paid note correct.';

	/// en: 'You find this paid note misleading.'
	String get findPaidNoteMisleading => 'You find this paid note misleading.';

	/// en: 'Select at least one reason'
	String get selectOneReason => 'Select at least one reason';

	/// en: 'Rate helpful'
	String get rateHelpful => 'Rate helpful';

	/// en: 'Rate not helpful'
	String get rateNotHelpful => 'Rate not helpful';

	/// en: 'Rated helpful'
	String get ratedHelpful => 'Rated helpful';

	/// en: 'Rated not helpful'
	String get ratedNotHelpful => 'Rated not helpful';

	/// en: 'you rated this as helpful'
	String get youRatedHelpful => 'you rated this as helpful';

	/// en: 'you rated this as not helpful'
	String get youRatedNotHelpful => 'you rated this as not helpful';

	/// en: 'Do you find this helpful?'
	String get findThisHelpful => 'Do you find this helpful?';

	/// en: 'Do you find this not helpful?'
	String get findThisNotHelpful => 'Do you find this not helpful?';

	/// en: 'Set your rating'
	String get setYourRating => 'Set your rating';

	/// en: 'What do you think of that?'
	String get whatThinkOfThat => 'What do you think of that?';

	/// en: 'Note: changing your rating will only be valid for 5 minutes, after that you will no longer have the option to undo or change it.'
	String get changeRatingNote => 'Note: changing your rating will only be valid for 5 minutes, after that you will no longer have the option to undo or change it.';

	/// en: 'Paid note'
	String get paidNote => 'Paid note';

	/// en: 'Undo'
	String get undo => 'Undo';

	/// en: 'Undo rating'
	String get undoRating => 'Undo rating';

	/// en: 'You are about to undo your rating, do you wish to proceed?'
	String get undoRatingDesc => 'You are about to undo your rating, do you wish to proceed?';

	/// en: 'See all attempts'
	String get seeAllAttempts => 'See all attempts';

	/// en: 'Add note'
	String get addNote => 'Add note';

	/// en: 'You have already contributed'
	String get alreadyContributed => 'You have already contributed';

	/// en: 'Notes from the community'
	String get notesFromCommunity => 'Notes from the community';

	/// en: 'It's quiet here! No community notes yet.'
	String get noCommunityNotes => 'It\'s quiet here! No community notes yet.';

	/// en: 'Not helpful'
	String get notHelpful => 'Not helpful';

	/// en: 'Sealed'
	String get sealed => 'Sealed';

	/// en: 'Not sealed'
	String get notSealed => 'Not sealed';

	/// en: 'Not sealed yet'
	String get notSealedYet => 'Not sealed yet';

	/// en: 'Needs more rating'
	String get needsMoreRating => 'Needs more rating';

	/// en: 'Source'
	String get source => 'Source';

	/// en: 'this note is awaiting community rating.'
	String get thisNoteAwaitRating => 'this note is awaiting community rating.';

	/// en: 'this note is awaiting community rating.'
	String get yourNoteAwaitRating => 'this note is awaiting community rating.';

	/// en: 'Top reasons selected by raters:'
	String get topReasonsSelected => 'Top reasons selected by raters:';

	/// en: 'No reasons are specified!'
	String get noReasonsSpecified => 'No reasons are specified!';

	/// en: 'Posted on {{date}}'
	String postedOn({required Object date}) => 'Posted on ${date}';

	/// en: 'Explanation'
	String get explanation => 'Explanation';

	/// en: 'Read about verifying notes'
	String get readAboutVerifyingNotes => 'Read about verifying notes';

	/// en: 'We've made an article for you to help you understand our purpose'
	String get readAboutVerifyingNotesDesc => 'We\'ve made an article for you to help you understand our purpose';

	/// en: 'Read article'
	String get readArticle => 'Read article';

	/// en: 'Why the verifying notes?'
	String get whyVerifyingNotes => 'Why the verifying notes?';

	/// en: 'Contribute to build understanding'
	String get contributeUnderstanding => 'Contribute to build understanding';

	/// en: 'Act in good faith'
	String get actGoodFaith => 'Act in good faith';

	/// en: 'Be helpful, even to those who disagree'
	String get beHelpful => 'Be helpful, even to those who disagree';

	/// en: 'Read more'
	String get readMore => 'Read more';

	/// en: 'New'
	String get newKey => 'New';

	/// en: 'Needs your helpful'
	String get needsYourHelp => 'Needs your helpful';

	/// en: 'Community wallet'
	String get communityWallet => 'Community wallet';

	/// en: 'No paid notes can be found.'
	String get noPaidNotesCanBeFound => 'No paid notes can be found.';

	/// en: 'Updates news'
	String get updatesNews => 'Updates news';

	/// en: 'Updates'
	String get updates => 'Updates';

	/// en: 'To be able to send zaps, please make sure to connect your bitcoin lightning wallet.'
	String get toBeAbleSendSats => 'To be able to send zaps, please make sure to connect your bitcoin lightning wallet.';

	/// en: 'Receive sats'
	String get receiveSats => 'Receive sats';

	/// en: 'Message (optional)'
	String get messageOptional => 'Message (optional)';

	/// en: 'Amount in sats'
	String get amountInSats => 'Amount in sats';

	/// en: 'Invoice code copied!'
	String get invoiceCopied => 'Invoice code copied!';

	/// en: 'Copy invoice'
	String get copyInvoice => 'Copy invoice';

	/// en: 'Ensure that your lightning address is well set'
	String get ensureLnSet => 'Ensure that your lightning address is well set';

	/// en: 'Error occured while generating invoice'
	String get errorGeneratingInvoice => 'Error occured while generating invoice';

	/// en: 'Generate invoice'
	String get generateInvoice => 'Generate invoice';

	/// en: 'QR code'
	String get qrCode => 'QR code';

	/// en: 'Scan & pay'
	String get scanPay => 'Scan & pay';

	/// en: 'Slide to pay'
	String get slideToPay => 'Slide to pay';

	/// en: 'Invalid invoice'
	String get invalidInvoice => 'Invalid invoice';

	/// en: 'It seems that the scanned invoice is invalid, re-scan and try again.'
	String get invalidInvoiceDesc => 'It seems that the scanned invoice is invalid, re-scan and try again.';

	/// en: 'Scan again'
	String get scanAgain => 'Scan again';

	/// en: 'Send sats'
	String get sendSats => 'Send sats';

	/// en: 'Send'
	String get send => 'Send';

	/// en: 'Recent transactions'
	String get recentTransactions => 'Recent transactions';

	/// en: 'No transactions can be found'
	String get noTransactionCanBeFound => 'No transactions can be found';

	/// en: 'Select a wallet to obtain latest transactions.'
	String get selectWalletTransactions => 'Select a wallet to obtain latest transactions.';

	/// en: 'No users can be found.'
	String get noUserCanBeFound => 'No users can be found.';

	/// en: 'Balance'
	String get balance => 'Balance';

	/// en: 'We could not retrieve your address from your NWC secret, kindly check your lightning address service provider to copy your address or to update your profile accordinaly.'
	String get noLnInNwc => 'We could not retrieve your address from your NWC secret, kindly check your lightning address service provider to copy your address or to update your profile accordinaly.';

	/// en: 'Copy lightning address'
	String get copyLn => 'Copy lightning address';

	/// en: 'Receive'
	String get receive => 'Receive';

	/// en: 'Click below to connect'
	String get clickBelowToConnect => 'Click below to connect';

	/// en: 'Connect with NWC'
	String get connectWithNwc => 'Connect with NWC';

	/// en: 'Paste NWC address'
	String get pasteNwcAddress => 'Paste NWC address';

	/// en: 'Create YakiHonne's wallet'
	String get createYakiWallet => 'Create YakiHonne\'s wallet';

	/// en: 'YakiHonne's NWC'
	String get yakiNwc => 'YakiHonne\'s NWC';

	/// en: 'Create wallet using YakiHonne's channel'
	String get yakiNwcDesc => 'Create wallet using YakiHonne\'s channel';

	/// en: 'Or use your wallet'
	String get orUseYourWallet => 'Or use your wallet';

	/// en: 'Nostr wallet connect'
	String get nostrWalletConnect => 'Nostr wallet connect';

	/// en: 'Native nostr wallet connection'
	String get nostrWalletConnectDesc => 'Native nostr wallet connection';

	/// en: 'Alby'
	String get alby => 'Alby';

	/// en: 'Alby connect'
	String get albyConnect => 'Alby connect';

	/// en: 'Note: All the data related to your wallet will be safely and securely stored locally and are never shared outside the confines of the application.'
	String get walletDataNote => 'Note: All the data related to your wallet will be safely and securely stored locally and are never shared outside the confines of the application.';

	/// en: 'Available wallets'
	String get availableWallets => 'Available wallets';

	/// en: 'You have no wallet linked to your profile.'
	String get noWalletLinkedToYouProfile => 'You have no wallet linked to your profile.';

	/// en: 'None of the connected wallets are linked to your profile.'
	String get noWalletConnectedToYourProfile => 'None of the connected wallets are linked to your profile.';

	/// en: 'Click'
	String get click => 'Click';

	/// en: 'on your selected wallet & link it.'
	String get onSelectedWalletLinkIt => 'on your selected wallet & link it.';

	/// en: 'No wallet can be found'
	String get noWalletCanBeFound => 'No wallet can be found';

	/// en: 'Currently linked with your profile for zaps receiving'
	String get currentlyLinkedMessage => 'Currently linked with your profile for zaps receiving';

	/// en: 'Linked'
	String get linked => 'Linked';

	/// en: 'Link wallet'
	String get linkWallet => 'Link wallet';

	/// en: 'You are about to override your previous wallet and link a new one to your profile, do you wish to proceed?'
	String get linkWalletDesc => 'You are about to override your previous wallet and link a new one to your profile, do you wish to proceed?';

	/// en: 'Copy NWC'
	String get copyNwc => 'Copy NWC';

	/// en: 'NWC has been successfuly copied!'
	String get nwcCopied => 'NWC has been successfuly copied!';

	/// en: 'Delete wallet'
	String get deleteWallet => 'Delete wallet';

	/// en: 'You are about to delete this wallet, do you wish to proceed?'
	String get deleteWalletDesc => 'You are about to delete this wallet, do you wish to proceed?';

	/// en: '{{name}} sent you {{number}} Sats'
	String userSentSat({required Object name, required Object number}) => '${name} sent you ${number} Sats';

	/// en: '{{name}} received from you {{number}} Sats'
	String userReceivedSat({required Object name, required Object number}) => '${name} received from you ${number} Sats';

	/// en: 'You sent {{number}} Sats'
	String ownSentSat({required Object number}) => 'You sent ${number} Sats';

	/// en: 'You received {{number}} Sats'
	String ownReceivedSat({required Object number}) => 'You received ${number} Sats';

	/// en: 'Comment'
	String get comment => 'Comment';

	/// en: 'Support YakiHonne'
	String get supportYakihonne => 'Support YakiHonne';

	/// en: 'Fuel YakiHonne's growth! Your support drives new features and a better experience for everyone.'
	String get fuelYakihonne => 'Fuel YakiHonne\'s growth! Your support drives new features and a better experience for everyone.';

	/// en: '❤︎ Support us'
	String get supportUs => '❤︎ Support us';

	/// en: 'People to follow'
	String get peopleToFollow => 'People to follow';

	/// en: 'Donations'
	String get donations => 'Donations';

	/// en: 'In {{name}}'
	String inTag({required Object name}) => 'In ${name}';

	/// en: 'Share profile'
	String get shareProfile => 'Share profile';

	/// en: 'Share your profile to reach more people, connect with others, and grow your network'
	String get shareProfileDesc => 'Share your profile to reach more people, connect with others, and grow your network';

	/// en: 'more...'
	String get moreDots => 'more...';

	/// en: 'Comments'
	String get comments => 'Comments';

	/// en: 'No comments can be found'
	String get noCommentsCanBeFound => 'No comments can be found';

	/// en: 'Be the first to comment on this video !'
	String get beFirstCommentThisVideo => 'Be the first to comment on this video !';

	/// en: 'Error while loading the video'
	String get errorLoadingVideo => 'Error while loading the video';

	/// en: 'See also'
	String get seeAlso => 'See also';

	/// en: '{{number}} view'
	String viewsNumber({required Object number}) => '${number} view';

	/// en: 'Upvotes'
	String get upvotes => 'Upvotes';

	/// en: 'Downvotes'
	String get downvotes => 'Downvotes';

	/// en: 'Views'
	String get views => 'Views';

	/// en: 'created at {{date1}}, edited on {{date2}}'
	String createdAtEditedAt({required Object date1, required Object date2}) => 'created at ${date1}, edited on ${date2}';

	/// en: 'Loading'
	String get loading => 'Loading';

	/// en: 'Release to load more'
	String get releaseToLoad => 'Release to load more';

	/// en: 'finished!'
	String get finished => 'finished!';

	/// en: 'No more data'
	String get noMoreData => 'No more data';

	/// en: 'Refreshed'
	String get refreshed => 'Refreshed';

	/// en: 'Refreshing'
	String get refreshing => 'Refreshing';

	/// en: 'Pull to refresh'
	String get pullToRefresh => 'Pull to refresh';

	/// en: 'Suggested interests'
	String get suggestedInterests => 'Suggested interests';

	/// en: 'Reveal'
	String get reveal => 'Reveal';

	/// en: 'I want to share this revenues'
	String get wantToShareRevenues => 'I want to share this revenues';

	/// en: 'Split revenues with users'
	String get splitRevenuesWithUsers => 'Split revenues with users';

	/// en: 'Add user'
	String get addUser => 'Add user';

	/// en: 'Select a date'
	String get selectAdate => 'Select a date';

	/// en: 'Clear date'
	String get clearDate => 'Clear date';

	/// en: 'Oops! Nothing to show here!'
	String get nothingToShowHere => 'Oops! Nothing to show here!';

	/// en: 'Confirm payment'
	String get confirmPayment => 'Confirm payment';

	/// en: 'Pay with NWC'
	String get payWithNwc => 'Pay with NWC';

	/// en: 'Important'
	String get important => 'Important';

	/// en: 'Adjust volume'
	String get adjustVolume => 'Adjust volume';

	/// en: 'Adjust speed'
	String get adjustSpeed => 'Adjust speed';

	/// en: 'Update interests'
	String get updateInterests => 'Update interests';

	/// en: 'You're using view mode'
	String get usingViewMode => 'You\'re using view mode';

	/// en: 'Sign in with your private key and join the community.'
	String get usingViewModeDesc => 'Sign in with your private key and join the community.';

	/// en: 'No internetAccess'
	String get noInternetAccess => 'No internetAccess';

	/// en: 'Check your modem or router'
	String get checkModelRouter => 'Check your modem or router';

	/// en: 'Reconnect to a wifi'
	String get reconnectWifi => 'Reconnect to a wifi';

	/// en: 'Something went wrong !'
	String get somethingWentWrong => 'Something went wrong !';

	/// en: 'It looks like something happened while loading the data, try again!'
	String get somethingWentWrongDesc => 'It looks like something happened while loading the data, try again!';

	/// en: 'Try again'
	String get tryAgain => 'Try again';

	/// en: 'Post could not be found'
	String get postNotFound => 'Post could not be found';

	/// en: 'user'
	String get user => 'user';

	/// en: 'view'
	String get view => 'view';

	/// en: 'It's live!'
	String get itsLive => 'It\'s live!';

	/// en: 'Spread the word by sharing your content everywhere.'
	String get spreadWordSharingContent => 'Spread the word by sharing your content everywhere.';

	/// en: 'Successful relays'
	String get successfulRelays => 'Successful relays';

	/// en: 'No relays can be found'
	String get noRelaysCanBeFound => 'No relays can be found';

	/// en: 'dismiss'
	String get dismiss => 'dismiss';

	/// en: 'You are attempting to login to a deleted account.'
	String get deleteAccountMessage => 'You are attempting to login to a deleted account.';

	/// en: 'Exit'
	String get exit => 'Exit';

	/// en: 'Share content'
	String get shareContent => 'Share content';

	/// en: 'Profile'
	String get profile => 'Profile';

	/// en: 'by'
	String get by => 'by';

	/// en: 'Share link'
	String get shareLink => 'Share link';

	/// en: 'Share image'
	String get shareImage => 'Share image';

	/// en: 'Share note id'
	String get shareNoteId => 'Share note id';

	/// en: 'Share nprofile'
	String get shareNprofile => 'Share nprofile';

	/// en: 'Share naddr'
	String get shareNaddr => 'Share naddr';

	/// en: 'Bio: {{content}}'
	String bio({required Object content}) => 'Bio: ${content}';

	/// en: 'Earn SATs'
	String get earnSats => 'Earn SATs';

	/// en: 'Help us provide more decentralized insights to review this paid note.'
	String get earnSatsDesc => 'Help us provide more decentralized insights to review this paid note.';

	/// en: 'Verifying note'
	String get verifyingNote => 'Verifying note';

	/// en: 'Pick your image'
	String get pickYourImage => 'Pick your image';

	/// en: 'You can upload or paste a url for your preffered image'
	String get uploadPasteUrl => 'You can upload or paste a url for your preffered image';

	/// en: 'back'
	String get back => 'back';

	/// en: 'Camera'
	String get camera => 'Camera';

	/// en: 'Community widgets'
	String get communityWidgets => 'Community widgets';

	/// en: 'My widgets'
	String get myWidgets => 'My widgets';

	/// en: 'Unfollowing...'
	String get pendingUnfollowing => 'Unfollowing...';

	/// en: 'Following...'
	String get pendingFollowing => 'Following...';

	/// en: 'Zappers'
	String get zappers => 'Zappers';

	/// en: 'No zappers can be found.'
	String get noZappersCanBeFound => 'No zappers can be found.';

	/// en: 'Pay & Publish'
	String get payPublish => 'Pay & Publish';

	/// en: 'Note: Ensure that all the content that you provided is final since the publishing is deemed irreversible & the spent SATS are non refundable.'
	String get payPublishNote => 'Note: Ensure that all the content that you provided is final since the publishing is deemed irreversible & the spent SATS are non refundable.';

	/// en: '{{name}} has submitted a paid note'
	String userSubmittedPaidNote({required Object name}) => '${name} has submitted a paid note';

	/// en: 'Get invoice'
	String get getInvoice => 'Get invoice';

	/// en: 'Pay'
	String get pay => 'Pay';

	/// en: 'Compose'
	String get compose => 'Compose';

	/// en: 'Write something...'
	String get writeSomething => 'Write something...';

	/// en: 'A highlighted note for more exposure.'
	String get highlightedNote => 'A highlighted note for more exposure.';

	/// en: 'Type a valid poll question!'
	String get typeValidZapQuestion => 'Type a valid poll question!';

	/// en: 'Poll options'
	String get pollOptions => 'Poll options';

	/// en: 'Minimum satoshis'
	String get minimumSatoshis => 'Minimum satoshis';

	/// en: 'Min sats'
	String get minSats => 'Min sats';

	/// en: 'Max sats'
	String get maxSats => 'Max sats';

	/// en: 'Maximum satoshis'
	String get maximumSatoshis => 'Maximum satoshis';

	/// en: 'Poll close date'
	String get pollCloseDate => 'Poll close date';

	/// en: 'Options: {{number}}'
	String optionsNumber({required Object number}) => 'Options: ${number}';

	/// en: 'Zap splits'
	String get zapSplits => 'Zap splits';

	/// en: 'A minimum amount of 1 is required'
	String get minimumOfOneRequired => 'A minimum amount of 1 is required';

	/// en: 'The value should be between the min and max sats amount'
	String get valueBetweenMinMax => 'The value should be between the min and max sats amount';

	/// en: 'Write a comment (optional)'
	String get writeCommentOptional => 'Write a comment (optional)';

	/// en: 'Split zaps with'
	String get splitZapsWith => 'Split zaps with';

	/// en: 'This user cannot be zapped'
	String get useCannotBeZapped => 'This user cannot be zapped';

	/// en: 'Waiting for the generation of invoices.'
	String get waitingGenerationOfInvoice => 'Waiting for the generation of invoices.';

	/// en: 'An invoice for {{name}} has been generated'
	String userInvoiceGenerated({required Object name}) => 'An invoice for ${name} has been generated';

	/// en: 'Could not create an invoice for this user.'
	String get userInvoiceNotGenerated => 'Could not create an invoice for this user.';

	/// en: 'Pay {{number}} sats'
	String payAmount({required Object number}) => 'Pay ${number} sats';

	/// en: 'Generate invoices'
	String get generateInvoices => 'Generate invoices';

	/// en: 'User was zapped successfuly'
	String get userZappedSuccesfuly => 'User was zapped successfuly';

	/// en: 'A valid title needs to be used'
	String get useValidTitle => 'A valid title needs to be used';

	/// en: 'Error occured when adding the bookmark'
	String get errorAddingBookmark => 'Error occured when adding the bookmark';

	/// en: 'Bookmark list has been added'
	String get bookmarkAdded => 'Bookmark list has been added';

	/// en: 'Vote could not be submitted'
	String get voteNotSubmitted => 'Vote could not be submitted';

	/// en: 'For zap splits, there should be at least one person'
	String get zapSplitsMessage => 'For zap splits, there should be at least one person';

	/// en: 'An error occured while updating the curation'
	String get errorUpdatingCuration => 'An error occured while updating the curation';

	/// en: 'An error occured while adding the curation'
	String get errorAddingCuration => 'An error occured while adding the curation';

	/// en: 'Error occured while deleting content'
	String get errorDeletingContent => 'Error occured while deleting content';

	/// en: 'Error occured while signing the event'
	String get errorSigningEvent => 'Error occured while signing the event';

	/// en: 'Error occured while sending the event'
	String get errorSendingEvent => 'Error occured while sending the event';

	/// en: 'error occured while sending the message'
	String get errorSendingMessage => 'error occured while sending the message';

	/// en: 'User has been muted'
	String get userHasBeenMuted => 'User has been muted';

	/// en: 'User has been unmuted'
	String get userHasBeenUnmuted => 'User has been unmuted';

	/// en: 'message could not be decrypted'
	String get messageCouldNotBeDecrypted => 'message could not be decrypted';

	/// en: 'Interest list has been updated successfuly!'
	String get interestsUpdateMessage => 'Interest list has been updated successfuly!';

	/// en: 'Error occured while generating event'
	String get errorGeneratingEvent => 'Error occured while generating event';

	/// en: 'There should be at least one feed option available.'
	String get oneFeedOptionAvailable => 'There should be at least one feed option available.';

	/// en: 'Wallet has been created successfuly'
	String get walletCreated => 'Wallet has been created successfuly';

	/// en: 'Wallet has been linked successfuly'
	String get walletLinked => 'Wallet has been linked successfuly';

	/// en: 'Error occured while creating wallet'
	String get errorCreatingWallet => 'Error occured while creating wallet';

	/// en: 'Wallet cannot be linked. Wrong lighting address'
	String get walletNotLinked => 'Wallet cannot be linked. Wrong lighting address';

	/// en: 'Invalid pairing secret'
	String get invalidPairingSecret => 'Invalid pairing secret';

	/// en: 'Error occured while setting up the token'
	String get errorSettingToken => 'Error occured while setting up the token';

	/// en: 'Nostr wallet connect has been initialized'
	String get nwcInitialized => 'Nostr wallet connect has been initialized';

	/// en: 'You have no wallet linked to your profile, do you wish to link this wallet?'
	String get noWalletLinkedMessage => 'You have no wallet linked to your profile, do you wish to link this wallet?';

	/// en: 'Error occured while using wallet!'
	String get errorUsingWallet => 'Error occured while using wallet!';

	/// en: 'Make sure you submit a valid data'
	String get submitValidData => 'Make sure you submit a valid data';

	/// en: 'Make sure you submit a valid invoice'
	String get submitValidInvoice => 'Make sure you submit a valid invoice';

	/// en: 'Payment succeeded'
	String get paymentSucceeded => 'Payment succeeded';

	/// en: 'Payment failed'
	String get paymentFailed => 'Payment failed';

	/// en: 'Not enough balance to make this payment.'
	String get notEnoughBalance => 'Not enough balance to make this payment.';

	/// en: 'Permission to pay invoices is not granted.'
	String get permissionInvoiceNotGranted => 'Permission to pay invoices is not granted.';

	/// en: 'All the users have been zapped!'
	String get allUsersZapped => 'All the users have been zapped!';

	/// en: 'Partial users are zapped!'
	String get partialUsersZapped => 'Partial users are zapped!';

	/// en: 'No user has been zapped!'
	String get noUserZapped => 'No user has been zapped!';

	/// en: 'Error occured while zapping users'
	String get errorZappingUsers => 'Error occured while zapping users';

	/// en: 'Select a default wallet in the settings.'
	String get selectDefaultWallet => 'Select a default wallet in the settings.';

	/// en: 'No invoices are available'
	String get noInvoiceAvailable => 'No invoices are available';

	/// en: 'Invoice has been paid successfuly'
	String get invoicePaid => 'Invoice has been paid successfuly';

	/// en: 'Error occured while paying using invoice'
	String get errorPayingInvoice => 'Error occured while paying using invoice';

	/// en: 'Error while using external wallet.'
	String get errorUsingExternalWallet => 'Error while using external wallet.';

	/// en: 'Payment Surpasses the maximum amount allowed.'
	String get paymentSurpassMax => 'Payment Surpasses the maximum amount allowed.';

	/// en: 'Error occured while sending sats'
	String get errorSendingSats => 'Error occured while sending sats';

	/// en: 'Set a sats amount greater than 0'
	String get setSatsMoreThanZero => 'Set a sats amount greater than 0';

	/// en: 'Process has been completed'
	String get processCompleted => 'Process has been completed';

	/// en: 'Relaying stuff...'
	String get relayingStuff => 'Relaying stuff...';

	/// en: 'Amber app is not installed'
	String get amberNotInstalled => 'Amber app is not installed';

	/// en: 'You are already logged in!'
	String get alreadyLoggedIn => 'You are already logged in!';

	/// en: 'You are logged in!'
	String get loggedIn => 'You are logged in!';

	/// en: 'Attempt to connect with Amber has been rejected.'
	String get attemptConnectAmber => 'Attempt to connect with Amber has been rejected.';

	/// en: 'Error ocurred while uploading image'
	String get errorUploadingImage => 'Error ocurred while uploading image';

	/// en: 'Invalid private key!'
	String get invalidPrivateKey => 'Invalid private key!';

	/// en: 'Invalid hex key!'
	String get invalidHexKey => 'Invalid hex key!';

	/// en: 'Fetching article'
	String get fetchingArticle => 'Fetching article';

	/// en: 'Article could not be found'
	String get articleNotFound => 'Article could not be found';

	/// en: 'Fetching curation'
	String get fetchingCuration => 'Fetching curation';

	/// en: 'Curation could not be found'
	String get curationNotFound => 'Curation could not be found';

	/// en: 'Fetching smart widget'
	String get fetchingSmartWidget => 'Fetching smart widget';

	/// en: 'Smart widget could not be found'
	String get smartWidgetNotFound => 'Smart widget could not be found';

	/// en: 'Fetching video'
	String get fetchingVideo => 'Fetching video';

	/// en: 'Video could not be found'
	String get videoNotFound => 'Video could not be found';

	/// en: 'Fetching note'
	String get fetchingNote => 'Fetching note';

	/// en: 'Note could not be found'
	String get noteNotFound => 'Note could not be found';

	/// en: 'Event could not be found'
	String get eventNotFound => 'Event could not be found';

	/// en: 'Verified note could not be found'
	String get verifiedNoteNotFound => 'Verified note could not be found';

	/// en: 'Event could not be recognized'
	String get eventNotRecognized => 'Event could not be recognized';

	/// en: 'Fetching event from user's relays'
	String get fetchingEventUserRelays => 'Fetching event from user\'s relays';

	/// en: 'Fetching profile'
	String get fetchingProfile => 'Fetching profile';

	/// en: 'Fetching event'
	String get fetchingEvent => 'Fetching event';

	/// en: 'You are logged in to Yakihonne's chest'
	String get loggedToYakiChest => 'You are logged in to Yakihonne\'s chest';

	/// en: 'Error occured while logging in to Yakihonne's chest'
	String get errorLoggingYakiChest => 'Error occured while logging in to Yakihonne\'s chest';

	/// en: 'Relay already in use'
	String get relayInUse => 'Relay already in use';

	/// en: 'Error occured while connecting to relay'
	String get errorConnectingRelay => 'Error occured while connecting to relay';

	/// en: 'Make sure to get a valid lud16/lud06.'
	String get submitValidLud => 'Make sure to get a valid lud16/lud06.';

	/// en: 'Error occured while updating data'
	String get errorUpdatingData => 'Error occured while updating data';

	/// en: 'Updated successfuly'
	String get updatedSuccesfuly => 'Updated successfuly';

	/// en: 'Relays list has been updated'
	String get relaysListUpdated => 'Relays list has been updated';

	/// en: 'Could not update relays list'
	String get couldNotUpdateRelaysList => 'Could not update relays list';

	/// en: 'Error occured while updating relays list'
	String get errorUpdatingRelaysList => 'Error occured while updating relays list';

	/// en: 'Error occured while claimaing a reward'
	String get errorClaimingReward => 'Error occured while claimaing a reward';

	/// en: 'Error occured while decoding data'
	String get errorDecodingData => 'Error occured while decoding data';

	/// en: 'Logging in...'
	String get loggingIn => 'Logging in...';

	/// en: 'Logging out...'
	String get loggingOut => 'Logging out...';

	/// en: 'Disconnecting...'
	String get disconnecting => 'Disconnecting...';

	/// en: 'Your rating has been submitted, check your rewards page to claim your rating reward'
	String get ratingSubmittedCheckReward => 'Your rating has been submitted, check your rewards page to claim your rating reward';

	/// en: 'Error occured while submitting your rating'
	String get errorSubmittingRating => 'Error occured while submitting your rating';

	/// en: 'Your verified note has been added, check your rewards page to claim your writing reward'
	String get verifiedNoteAdded => 'Your verified note has been added, check your rewards page to claim your writing reward';

	/// en: 'Error occured while adding your verified note'
	String get errorAddingVerifiedNote => 'Error occured while adding your verified note';

	/// en: 'Your rating has been deleted'
	String get ratingDeleted => 'Your rating has been deleted';

	/// en: 'Error occured while deleting your rating'
	String get errorDeletingRating => 'Error occured while deleting your rating';

	/// en: 'Auto-saved article has been deleted'
	String get autoSavedArticleDeleted => 'Auto-saved article has been deleted';

	/// en: 'Your article has been published!'
	String get articlePublished => 'Your article has been published!';

	/// en: 'An error occured while adding the article'
	String get errorAddingArticle => 'An error occured while adding the article';

	/// en: 'Write down a valid note!'
	String get writeValidNote => 'Write down a valid note!';

	/// en: 'Make sure to set up your outbox relays'
	String get setOutboxRelays => 'Make sure to set up your outbox relays';

	/// en: 'Note has been published!'
	String get notePublished => 'Note has been published!';

	/// en: 'Paid note has been published!'
	String get paidNotePublished => 'Paid note has been published!';

	/// en: 'It seemse that you didn't pay the invoice, recheck again'
	String get invoiceNotPayed => 'It seemse that you didn\'t pay the invoice, recheck again';

	/// en: 'Auto-saved smart widget has been deleted'
	String get autoSavedSMdeleted => 'Auto-saved smart widget has been deleted';

	/// en: 'Error occured while uploading the media'
	String get errorUploadingMedia => 'Error occured while uploading the media';

	/// en: 'Smart widget has been published successfuly'
	String get smartWidgetPublishedSuccessfuly => 'Smart widget has been published successfuly';

	/// en: 'An error occured while adding the smart widget'
	String get errorAddingWidget => 'An error occured while adding the smart widget';

	/// en: 'Make sure to set all the required content.'
	String get setAllRequiredContent => 'Make sure to set all the required content.';

	/// en: 'No event with this id can be found!'
	String get noEventIdCanBeFound => 'No event with this id can be found!';

	/// en: 'This event is not a valid video event!'
	String get notValidVideoEvent => 'This event is not a valid video event!';

	/// en: 'This nevent has an empty url'
	String get emptyVideoUrl => 'This nevent has an empty url';

	/// en: 'Please submit a valid video event'
	String get submitValidVideoEvent => 'Please submit a valid video event';

	/// en: 'Error occured while uploading the video'
	String get errorUploadingVideo => 'Error occured while uploading the video';

	/// en: 'An error occured while adding the video'
	String get errorAddingVideo => 'An error occured while adding the video';

	/// en: 'Make sure to submit valid minimum & maximum satoshis'
	String get submitMinMaxSats => 'Make sure to submit valid minimum & maximum satoshis';

	/// en: 'Make sure to submit valid close date.'
	String get submitValidCloseDate => 'Make sure to submit valid close date.';

	/// en: 'Make sure to submit valid options.'
	String get submitValidOptions => 'Make sure to submit valid options.';

	/// en: 'Poll zap has been published!'
	String get pollZapPublished => 'Poll zap has been published!';

	/// en: 'Relays could not be reached'
	String get relaysNotReached => 'Relays could not be reached';

	/// en: 'Login to Yakihonne's chest, accumulate points by being active on the platform and win precious awards!'
	String get loginYakiChestPoints => 'Login to Yakihonne\'s chest, accumulate points by being active on the platform and win precious awards!';

	/// en: 'Inaccessible link'
	String get inaccessibleLink => 'Inaccessible link';

	/// en: 'Media exceeds the maximum size which is 21 mb'
	String get mediaExceedsMaxSize => 'Media exceeds the maximum size which is 21 mb';

	/// en: 'Fetching user inbox relays'
	String get fetchingUserInboxRelays => 'Fetching user inbox relays';

	/// en: '{{name}} zapped you {{number}} sats'
	String userZappedYou({required Object name, required Object number}) => '${name} zapped you ${number} sats';

	/// en: '{{name}} reacted {{reaction}} to you'
	String userReactedYou({required Object name, required Object reaction}) => '${name} reacted ${reaction} to you';

	/// en: '{{name}} reposted your content'
	String userRepostedYou({required Object name}) => '${name} reposted your content';

	/// en: '{{name}} mentioned you in a comment'
	String userMentionedYouInComment({required Object name}) => '${name} mentioned you in a comment';

	/// en: '{{name}} mentioned you in a note'
	String userMentionedYouInNote({required Object name}) => '${name} mentioned you in a note';

	/// en: '{{name}} mentioned you in a paid note'
	String userMentionedYouInPaidNote({required Object name}) => '${name} mentioned you in a paid note';

	/// en: '{{name}} mentioned you in an article'
	String userMentionedYouInArticle({required Object name}) => '${name} mentioned you in an article';

	/// en: '{{name}} mentioned you in a video'
	String userMentionedYouInVideo({required Object name}) => '${name} mentioned you in a video';

	/// en: '{{name}} mentioned you in a curation'
	String userMentionedYouInCuration({required Object name}) => '${name} mentioned you in a curation';

	/// en: '{{name}} mentioned you in a smart widget'
	String userMentionedYouInSmartWidget({required Object name}) => '${name} mentioned you in a smart widget';

	/// en: '{{name}} mentioned you in a poll'
	String userMentionedYouInPoll({required Object name}) => '${name} mentioned you in a poll';

	/// en: '{{name}} published a paid note'
	String userPublishedPaidNote({required Object name}) => '${name} published a paid note';

	/// en: '{{name}} published an article'
	String userPublishedArticle({required Object name}) => '${name} published an article';

	/// en: '{{name}} published a video'
	String userPublishedVideo({required Object name}) => '${name} published a video';

	/// en: '{{name}} published a curation'
	String userPublishedCuration({required Object name}) => '${name} published a curation';

	/// en: '{{name}} published a smart widget'
	String userPublishedSmartWidget({required Object name}) => '${name} published a smart widget';

	/// en: '{{name}} published a poll'
	String userPublishedPoll({required Object name}) => '${name} published a poll';

	/// en: '{{name}} zapped your article {{number}} sats'
	String userZappedYourArticle({required Object name, required Object number}) => '${name} zapped your article ${number} sats';

	/// en: '{{name}} zapped your curation {{number}} sats'
	String userZappedYourCuration({required Object name, required Object number}) => '${name} zapped your curation ${number} sats';

	/// en: '{{name}} zapped your video {{number}} sats'
	String userZappedYourVideo({required Object name, required Object number}) => '${name} zapped your video ${number} sats';

	/// en: '{{name}} zapped your smart widget {{number}} sats'
	String userZappedYourSmartWidget({required Object name, required Object number}) => '${name} zapped your smart widget ${number} sats';

	/// en: '{{name}} zapped your poll {{number}} sats'
	String userZappedYourPoll({required Object name, required Object number}) => '${name} zapped your poll ${number} sats';

	/// en: '{{name}} zapped your note {{number}} sats'
	String userZappedYourNote({required Object name, required Object number}) => '${name} zapped your note ${number} sats';

	/// en: '{{name}} zapped your paid note {{number}} sats'
	String userZappedYourPaidNote({required Object name, required Object number}) => '${name} zapped your paid note ${number} sats';

	/// en: '{{name}} reacted {{reaction}} to your article'
	String userReactedYourArticle({required Object name, required Object reaction}) => '${name} reacted ${reaction} to your article';

	/// en: '{{name}} reacted {{reaction}} to your curation'
	String userReactedYourCuration({required Object name, required Object reaction}) => '${name} reacted ${reaction} to your curation';

	/// en: '{{name}} reacted {{reaction}} to your video'
	String userReactedYourVideo({required Object name, required Object reaction}) => '${name} reacted ${reaction} to your video';

	/// en: '{{name}} reacted {{reaction}} to your smart widget'
	String userReactedYourSmartWidget({required Object name, required Object reaction}) => '${name} reacted ${reaction} to your smart widget';

	/// en: '{{name}} reacted {{reaction}} to your poll'
	String userReactedYourPoll({required Object name, required Object reaction}) => '${name} reacted ${reaction} to your poll';

	/// en: '{{name}} reacted {{reaction}} to your note'
	String userReactedYourNote({required Object name, required Object reaction}) => '${name} reacted ${reaction} to your note';

	/// en: '{{name}} reacted {{reaction}} to your paid note'
	String userReactedYourPaidNote({required Object name, required Object reaction}) => '${name} reacted ${reaction} to your paid note';

	/// en: '{{name}} reacted {{reaction}} to your message'
	String userReactedYourMessage({required Object name, required Object reaction}) => '${name} reacted ${reaction} to your message';

	/// en: '{{name}} reposted your note'
	String userRepostedYourNote({required Object name}) => '${name} reposted your note';

	/// en: '{{name}} reposted your paid note'
	String userRepostedYourPaidNote({required Object name}) => '${name} reposted your paid note';

	/// en: '{{name}} replied to your article'
	String userRepliedYourArticle({required Object name}) => '${name} replied to your article';

	/// en: '{{name}} replied to your curation'
	String userRepliedYourCuration({required Object name}) => '${name} replied to your curation';

	/// en: '{{name}} replied to your video'
	String userRepliedYourVideo({required Object name}) => '${name} replied to your video';

	/// en: '{{name}} replied to your smart widget'
	String userRepliedYourSmartWidget({required Object name}) => '${name} replied to your smart widget';

	/// en: '{{name}} replied to your poll'
	String userRepliedYourPoll({required Object name}) => '${name} replied to your poll';

	/// en: '{{name}} replied to your note'
	String userRepliedYourNote({required Object name}) => '${name} replied to your note';

	/// en: '{{name}} replied to your paid note'
	String userRepliedYourPaidNote({required Object name}) => '${name} replied to your paid note';

	/// en: '{{name}} commented on your article'
	String userCommentedYourArticle({required Object name}) => '${name} commented on your article';

	/// en: '{{name}} commented on your curation'
	String userCommentedYourCuration({required Object name}) => '${name} commented on your curation';

	/// en: '{{name}} commented on your video'
	String userCommentedYourVideo({required Object name}) => '${name} commented on your video';

	/// en: '{{name}} commented on your smart widget'
	String userCommentedYourSmartWidget({required Object name}) => '${name} commented on your smart widget';

	/// en: '{{name}} commented on your poll'
	String userCommentedYourPoll({required Object name}) => '${name} commented on your poll';

	/// en: '{{name}} commented on your note'
	String userCommentedYourNote({required Object name}) => '${name} commented on your note';

	/// en: '{{name}} commented on your paid note'
	String userCommentedYourPaidNote({required Object name}) => '${name} commented on your paid note';

	/// en: '{{name}} quoted your article'
	String userQuotedYourArticle({required Object name}) => '${name} quoted your article';

	/// en: '{{name}} quoted your curation'
	String userQuotedYourCuration({required Object name}) => '${name} quoted your curation';

	/// en: '{{name}} quoted your video'
	String userQuotedYourVideo({required Object name}) => '${name} quoted your video';

	/// en: '{{name}} quoted your note'
	String userQuotedYourNote({required Object name}) => '${name} quoted your note';

	/// en: '{{name}} quoted your paid note'
	String userQuotedYourPaidNote({required Object name}) => '${name} quoted your paid note';

	/// en: '{{name}} reacted {{reaction}} to an article you were mentioned in'
	String userReactedArticleYouIn({required Object name, required Object reaction}) => '${name} reacted ${reaction} to an article you were mentioned in';

	/// en: '{{name}} reacted {{reaction}} to a curation you were mentioned in'
	String userReactedCurationYouIn({required Object name, required Object reaction}) => '${name} reacted ${reaction} to a curation you were mentioned in';

	/// en: '{{name}} reacted {{reaction}} to a video you were mentioned in'
	String userReactedVideoYouIn({required Object name, required Object reaction}) => '${name} reacted ${reaction} to a video you were mentioned in';

	/// en: '{{name}} reacted {{reaction}} to a smart widget you were mentioned in'
	String userReactedSmartWidgetYouIn({required Object name, required Object reaction}) => '${name} reacted ${reaction} to a smart widget you were mentioned in';

	/// en: '{{name}} reacted {{reaction}} to a poll you were mentioned in'
	String userReactedPollYouIn({required Object name, required Object reaction}) => '${name} reacted ${reaction} to a poll you were mentioned in';

	/// en: '{{name}} reacted {{reaction}} to a note you were mentioned in'
	String userReactedNoteYouIn({required Object name, required Object reaction}) => '${name} reacted ${reaction} to a note you were mentioned in';

	/// en: '{{name}} reacted {{reaction}} to a paid note you were mentioned in'
	String userReactedPaidNoteYouIn({required Object name, required Object reaction}) => '${name} reacted ${reaction} to a paid note you were mentioned in';

	/// en: '{{name}} reposted a note you were mentioned in'
	String userRepostedNoteYouIn({required Object name}) => '${name} reposted a note you were mentioned in';

	/// en: '{{name}} reposted a paid note you were mentioned in'
	String userRepostedPaidNoteYouIn({required Object name}) => '${name} reposted a paid note you were mentioned in';

	/// en: '{{name}} replied to a article you were mentioned in'
	String userRepliedArticleYouIn({required Object name}) => '${name} replied to a article you were mentioned in';

	/// en: '{{name}} replied to a curation you were mentioned in'
	String userRepliedCurationYouIn({required Object name}) => '${name} replied to a curation you were mentioned in';

	/// en: '{{name}} replied to a video you were mentioned in'
	String userRepliedVideoYouIn({required Object name}) => '${name} replied to a video you were mentioned in';

	/// en: '{{name}} replied to a smart widget you were mentioned in'
	String userRepliedSmartWidgetYouIn({required Object name}) => '${name} replied to a smart widget you were mentioned in';

	/// en: '{{name}} replied to a poll you were mentioned in'
	String userRepliedPollYouIn({required Object name}) => '${name} replied to a poll you were mentioned in';

	/// en: '{{name}} replied to a note you were mentioned in'
	String userRepliedNoteYouIn({required Object name}) => '${name} replied to a note you were mentioned in';

	/// en: '{{name}} replied to a paid note you were mentioned in'
	String userRepliedPaidNoteYouIn({required Object name}) => '${name} replied to a paid note you were mentioned in';

	/// en: '{{name}} commented on an article you were mentioned in'
	String userCommentedArticleYouIn({required Object name}) => '${name} commented on an article you were mentioned in';

	/// en: '{{name}} commented on a curation you were mentioned in'
	String userCommentedCurationYouIn({required Object name}) => '${name} commented on a curation you were mentioned in';

	/// en: '{{name}} commented on a video you were mentioned in'
	String userCommentedVideoYouIn({required Object name}) => '${name} commented on a video you were mentioned in';

	/// en: '{{name}} commented on a smart you were mentioned in widget'
	String userCommentedSmartWidgetYouIn({required Object name}) => '${name} commented on a smart you were mentioned in widget';

	/// en: '{{name}} commented on a poll you were mentioned in'
	String userCommentedPollYouIn({required Object name}) => '${name} commented on a poll you were mentioned in';

	/// en: '{{name}} commented on a note you were mentioned in'
	String userCommentedNoteYouIn({required Object name}) => '${name} commented on a note you were mentioned in';

	/// en: '{{name}} commented on a paid you were mentioned in note'
	String userCommentedPaidNoteYouIn({required Object name}) => '${name} commented on a paid you were mentioned in note';

	/// en: '{{name}} quoted an article you were mentioned in'
	String userQuotedArticleYouIn({required Object name}) => '${name} quoted an article you were mentioned in';

	/// en: '{{name}} quoted a curation you were mentioned in'
	String userQuotedCurationYouIn({required Object name}) => '${name} quoted a curation you were mentioned in';

	/// en: '{{name}} quoted a video you were mentioned in'
	String userQuotedVideoYouIn({required Object name}) => '${name} quoted a video you were mentioned in';

	/// en: '{{name}} quoted a note you were mentioned in'
	String userQuotedNoteYouIn({required Object name}) => '${name} quoted a note you were mentioned in';

	/// en: '{{name}} quoted a paid note you were mentioned in'
	String userQuotedPaidNoteYouIn({required Object name}) => '${name} quoted a paid note you were mentioned in';

	/// en: '{{name}} reacted with {{reaction}}'
	String reactedWith({required Object name, required Object reaction}) => '${name} reacted with ${reaction}';

	/// en: 'Your verified note has been sealed.'
	String get verifiedNoteSealed => 'Your verified note has been sealed.';

	/// en: 'An verified note you have rated has been sealed.'
	String get verifiedNoteRateSealed => 'An verified note you have rated has been sealed.';

	/// en: '{{name}}'s video'
	String userNewVideo({required Object name}) => '${name}\'s video';

	/// en: 'Title: {{description}}'
	String titleData({required Object description}) => 'Title: ${description}';

	/// en: 'checkout my video'
	String get checkoutVideo => 'checkout my video';

	/// en: 'YakiHonne's notification'
	String get yakihonneNotification => 'YakiHonne\'s notification';

	/// en: 'Unknown's verified note'
	String get unknownVerifiedNote => 'Unknown\'s verified note';

	/// en: '{{name}}'s replied'
	String userReply({required Object name}) => '${name}\'s replied';

	/// en: '{{name}}'s new paid note'
	String userPaidNote({required Object name}) => '${name}\'s new paid note';

	/// en: 'Content: {{description}}'
	String contentData({required Object description}) => 'Content: ${description}';

	/// en: 'check out my paid note'
	String get checkoutPaidNote => 'check out my paid note';

	/// en: '{{name}}'s new curation'
	String userNewCuration({required Object name}) => '${name}\'s new curation';

	/// en: '{{name}}'s new article'
	String userNewArticle({required Object name}) => '${name}\'s new article';

	/// en: '{{name}}'s new smart widget'
	String userNewSmartWidget({required Object name}) => '${name}\'s new smart widget';

	/// en: 'check out my article'
	String get checkoutArticle => 'check out my article';

	/// en: 'check out my curation'
	String get checkoutCuration => 'check out my curation';

	/// en: 'check out my smart widget'
	String get checkoutSmartWidget => 'check out my smart widget';

	/// en: 'Language preferences'
	String get languagePreferences => 'Language preferences';

	/// en: 'Content Translation'
	String get contentTranslation => 'Content Translation';

	/// en: 'App language'
	String get appLanguage => 'App language';

	/// en: 'Api key (required)'
	String get apiKeyRequired => 'Api key (required)';

	/// en: 'Get API Key'
	String get getApiKey => 'Get API Key';

	/// en: 'See translation'
	String get seeTranslation => 'See translation';

	/// en: 'See original'
	String get seeOriginal => 'See original';

	/// en: 'Plan'
	String get plan => 'Plan';

	/// en: 'Free'
	String get free => 'Free';

	/// en: 'Pro'
	String get pro => 'Pro';

	/// en: 'Error occured while translating content.'
	String get errorTranslating => 'Error occured while translating content.';

	/// en: 'Missing API Key or expired subscription. Check Settings -> Language Preferences for more.'
	String get errorMissingKey => 'Missing API Key or expired subscription. Check Settings -> Language Preferences for more.';

	/// en: 'Coming soon'
	String get comingSoon => 'Coming soon';

	/// en: 'Content'
	String get content => 'Content';

	/// en: 'Expires on: {{date}}'
	String expiresOn({required Object date}) => 'Expires on: ${date}';

	/// en: 'Collapse note'
	String get collapseNote => 'Collapse note';

	/// en: 'Reactions'
	String get reactions => 'Reactions';

	/// en: 'Reposts'
	String get reposts => 'Reposts';

	/// en: 'Notifications are disabled!'
	String get notifDisabled => 'Notifications are disabled!';

	/// en: 'Notifications are disabled for this type, you can enable it in the notifications settings.'
	String get notifDisabledMessage => 'Notifications are disabled for this type, you can enable it in the notifications settings.';

	/// en: 'There should be at least one notification option available.'
	String get oneNotifOptionAvailable => 'There should be at least one notification option available.';

	/// en: 'Read all'
	String get readAll => 'Read all';

	/// en: 'Username is taken'
	String get usernameTaken => 'Username is taken';

	/// en: 'Username is required'
	String get usernameRequired => 'Username is required';

	/// en: 'Please ensure you securely save your NWC connection phrase, as we cannot assist with recovering lost wallets.'
	String get deleteWalletConfirmation => 'Please ensure you securely save your NWC connection phrase, as we cannot assist with recovering lost wallets.';

	/// en: 'Unsupported kind'
	String get unsupportedKind => 'Unsupported kind';

	/// en: 'Crashlytics'
	String get analyticsCrashlytics => 'Crashlytics';

	/// en: 'Crashlytics & cache'
	String get analyticsCache => 'Crashlytics & cache';

	/// en: 'Crashlytics have been turned on.'
	String get analyticsCacheOn => 'Crashlytics have been turned on.';

	/// en: 'Crashlytics have been turned off.'
	String get analyticsCacheOff => 'Crashlytics have been turned off.';

	/// en: 'You share no crashlytics with us at the moment.'
	String get shareNoUsage => 'You share no crashlytics with us at the moment.';

	/// en: 'Want to share crashlytics?'
	String get wantShareAnalytics => 'Want to share crashlytics?';

	/// en: 'YakiHonne's crashlytics'
	String get yakihonneAnCr => 'YakiHonne\'s crashlytics';

	/// en: 'Collecting anonymized crashlytics is vital for refining our app's features and user experience. It enables us to identify user preferences, enhance popular features, and make informed optimizations, ensuring a more personalized and efficient app for our users.'
	String get crashlyticsTerms => 'Collecting anonymized crashlytics is vital for refining our app\'s features and user experience. It enables us to identify user preferences, enhance popular features, and make informed optimizations, ensuring a more personalized and efficient app for our users.';

	/// en: 'We collect anonymised crashlytics to improve the app experience.'
	String get collectAnonymised => 'We collect anonymised crashlytics to improve the app experience.';

	/// en: 'Link wallet with your profile'
	String get linkWalletToProfile => 'Link wallet with your profile';

	/// en: 'The linked wallet is going to be used to receive sats'
	String get linkWalletToProfileDesc => 'The linked wallet is going to be used to receive sats';

	/// en: 'You have no wallet linked to your profile consider linking one of yours in the menu above'
	String get noWalletLinked => 'You have no wallet linked to your profile consider linking one of yours in the menu above';

	/// en: 'Add poll'
	String get addPoll => 'Add poll';

	/// en: 'Browse polls'
	String get browsePolls => 'Browse polls';

	/// en: 'MACI poll'
	String get maciPolls => 'MACI poll';

	/// en: 'Beta'
	String get beta => 'Beta';

	/// en: 'Choose a poll type'
	String get choosePollType => 'Choose a poll type';

	/// en: 'Created'
	String get created => 'Created';

	/// en: 'Tallying'
	String get tallying => 'Tallying';

	/// en: 'Ended'
	String get ended => 'Ended';

	/// en: 'Closed'
	String get closed => 'Closed';

	/// en: 'Vote results by'
	String get voteResultsBy => 'Vote results by';

	/// en: 'votes'
	String get votes => 'votes';

	/// en: 'Voice credit'
	String get voiceCredit => 'Voice credit';

	/// en: 'View details'
	String get viewDetails => 'View details';

	/// en: 'Signup'
	String get signup => 'Signup';

	/// en: 'Could not download proofs'
	String get notDownloadProof => 'Could not download proofs';

	/// en: 'Name'
	String get name => 'Name';

	/// en: 'Status'
	String get status => 'Status';

	/// en: 'Circuit'
	String get circuit => 'Circuit';

	/// en: 'Voting system'
	String get votingSystem => 'Voting system';

	/// en: 'Proof system'
	String get proofSystem => 'Proof system';

	/// en: 'Gas station'
	String get gasStation => 'Gas station';

	/// en: '(total fund)'
	String get totalFund => '(total fund)';

	/// en: 'Round start'
	String get roundStart => 'Round start';

	/// en: 'Round end'
	String get roundEnd => 'Round end';

	/// en: 'Operator'
	String get operator => 'Operator';

	/// en: 'Contract creator'
	String get contractCreator => 'Contract creator';

	/// en: 'Contract address'
	String get contractAddress => 'Contract address';

	/// en: 'Block height'
	String get blockHeight => 'Block height';

	/// en: '{{number}} (at contract creation)'
	String atContractCreation({required Object number}) => '${number} (at contract creation)';

	/// en: 'ZK proofs'
	String get zkProofs => 'ZK proofs';

	/// en: 'Download proofs'
	String get downloadZkProofs => 'Download proofs';

	/// en: 'Wallet Connection String'
	String get walletConnectionString => 'Wallet Connection String';

	/// en: 'Please make sure to securely copy or export your wallet connection string. We do not store this information, and if lost, it cannot be recovered.'
	String get walletConnectionStringDesc => 'Please make sure to securely copy or export your wallet connection string. We do not store this information, and if lost, it cannot be recovered.';

	/// en: 'Export'
	String get export => 'Export';

	/// en: 'Log out'
	String get logout => 'Log out';

	/// en: 'Export & log out'
	String get exportAndLogout => 'Export & log out';

	/// en: 'It looks like you have wallets linked to your account. Please download your wallet secrets before logging out.'
	String get exportWalletsDesc => 'It looks like you have wallets linked to your account. Please download your wallet secrets before logging out.';

	/// en: 'Manage wallets'
	String get manageWallets => 'Manage wallets';

	/// en: 'Round duration'
	String get roundDuration => 'Round duration';

	/// en: 'Starts at: {{date}}'
	String startAt({required Object date}) => 'Starts at: ${date}';

	/// en: 'Log in'
	String get loginAction => 'Log in';

	/// en: 'Add picture'
	String get addPicture => 'Add picture';

	/// en: 'Edit picture'
	String get editPicture => 'Edit picture';

	/// en: 'Export keys'
	String get exportKeys => 'Export keys';

	/// en: 'Muted user'
	String get mutedUser => 'Muted user';

	/// en: 'Inaccessible content'
	String get unaccessibleContent => 'Inaccessible content';

	/// en: 'You have muted this user, consider unmuting to view this content'
	String get mutedUserDesc => 'You have muted this user, consider unmuting to view this content';

	/// en: 'This comment is hidden'
	String get commentHidden => 'This comment is hidden';

	/// en: 'Upcoming'
	String get upcoming => 'Upcoming';

	/// en: 'Export credentials'
	String get exportCredentials => 'Export credentials';

	/// en: 'Log in to Yakihonne'
	String get loginToYakihonne => 'Log in to Yakihonne';

	/// en: 'Already a user?'
	String get alreadyUser => 'Already a user?';

	/// en: 'Create poll'
	String get createPoll => 'Create poll';

	/// en: 'Gas station (total funded)'
	String get gasStationTotal => 'Gas station (total funded)';

	/// en: 'Gas station (remaining balance)'
	String get gasStationRemaining => 'Gas station (remaining balance)';

	/// en: 'Paste'
	String get paste => 'Paste';

	/// en: 'Manual'
	String get manual => 'Manual';

	/// en: 'Contacts'
	String get contacts => 'Contacts';

	/// en: 'Type lightning Address, Lightning invoice or LNURL'
	String get typeManualDesc => 'Type lightning Address, Lightning invoice or LNURL';

	/// en: 'Please use valid payment request'
	String get useValidPaymentRequest => 'Please use valid payment request';

	/// en: 'Save'
	String get save => 'Save';

	/// en: 'Image has been downloaded to your gallery'
	String get saveImageGallery => 'Image has been downloaded to your gallery';

	/// en: 'Error occured while downloading the image'
	String get errorSavingImage => 'Error occured while downloading the image';

	/// en: 'Image has been copied to your Clipboard'
	String get copyImageGallery => 'Image has been copied to your Clipboard';

	/// en: 'Error occured while copying the image'
	String get errorCopyImage => 'Error occured while copying the image';

	/// en: 'Scan'
	String get scan => 'Scan';

	/// en: 'Invalid lightning address'
	String get invalidLightningAddress => 'Invalid lightning address';

	/// en: 'You are about to delete your account, do you wish to proceed?'
	String get deleteAccountDesc => 'You are about to delete your account, do you wish to proceed?';

	/// en: 'Payment failed: check the validity of this invoice'
	String get paymentFailedInvoice => 'Payment failed: check the validity of this invoice';

	/// en: 'Set a valid sats amount'
	String get validSatsAmount => 'Set a valid sats amount';

	/// en: 'Placeholder'
	String get placeholder => 'Placeholder';

	/// en: 'Input field customization'
	String get inputFieldCustomization => 'Input field customization';

	/// en: 'Add input field'
	String get addInputField => 'Add input field';

	/// en: 'Add button'
	String get addButton => 'Add button';

	/// en: 'Select image'
	String get selectImage => 'Select image';

	/// en: 'Move left'
	String get moveLeft => 'Move left';

	/// en: 'Move right'
	String get moveRight => 'Move right';

	/// en: 'There should be at least one button available'
	String get buttonRequired => 'There should be at least one button available';

	/// en: 'It looks like you're using one of the custom functions that requires an input field component without embedding one in your smart widget, please add an input field so the function works properly.'
	String get missingInputDesc => 'It looks like you\'re using one of the custom functions that requires an input field component without embedding one in your smart widget, please add an input field so the function works properly.';

	/// en: 'Countdown'
	String get countdown => 'Countdown';

	/// en: 'Content ends at'
	String get contentEndsAt => 'Content ends at';

	/// en: 'Countdown time is mandatory'
	String get countdownTime => 'Countdown time is mandatory';

	/// en: 'Content ends date is mandatory'
	String get contentEndsDate => 'Content ends date is mandatory';

	/// en: 'Lightning address is mandatory'
	String get lnMandatory => 'Lightning address is mandatory';

	/// en: 'At least one profile is mandatory'
	String get pubkeysMandatory => 'At least one profile is mandatory';

	/// en: 'Buttons urls are mandatory'
	String get buttonNoUrl => 'Buttons urls are mandatory';

	/// en: 'Share widget image'
	String get shareWidgetImage => 'Share widget image';

	/// en: 'Input field'
	String get inputField => 'Input field';

	/// en: 'No replies'
	String get noReplies => 'No replies';

	/// en: 'Message'
	String get message => 'Message';

	/// en: 'Chat'
	String get chat => 'Chat';

	/// en: 'Only letters & numbers allowed'
	String get onlyLettersNumber => 'Only letters & numbers allowed';

	/// en: 'App cache'
	String get appCache => 'App cache';

	/// en: 'Cached data'
	String get cachedData => 'Cached data';

	/// en: 'Cached media'
	String get cachedMedia => 'Cached media';

	/// en: 'Cache has been cleared'
	String get cacheCleared => 'Cache has been cleared';

	/// en: 'It is preferable to restart the app upon clearing cache to ensure all changes take effect and the app runs smoothly'
	String get closeAppClearingCache => 'It is preferable to restart the app upon clearing cache to ensure all changes take effect and the app runs smoothly';

	/// en: 'Your app cache is growing in size. To ensure smooth performance, it's recommended to clear old data.'
	String get appCacheNotice => 'Your app cache is growing in size. To ensure smooth performance, it\'s recommended to clear old data.';

	/// en: 'Manage cache'
	String get manageCache => 'Manage cache';

	/// en: 'Filter by time'
	String get filterByTime => 'Filter by time';

	/// en: 'All time'
	String get allTime => 'All time';

	/// en: '1 month'
	String get oneMonth => '1 month';

	/// en: '3 months'
	String get threeMonths => '3 months';

	/// en: '6 months'
	String get sixMonths => '6 months';

	/// en: '1 year'
	String get oneYear => '1 year';

	/// en: 'Default zap amount'
	String get defaultZapAmount => 'Default zap amount';

	/// en: 'Enable one tap zap'
	String get oneTapZap => 'Enable one tap zap';

	/// en: 'Verify'
	String get verify => 'Verify';

	/// en: 'reset'
	String get reset => 'reset';

	/// en: 'App cannot be verified or invalid'
	String get appCannotVerified => 'App cannot be verified or invalid';

	/// en: 'Use a valid app url'
	String get useValidAppUrl => 'Use a valid app url';

	/// en: 'App'
	String get app => 'App';

	/// en: 'User not connected'
	String get userNotConnected => 'User not connected';

	/// en: 'This user cannot sign events.'
	String get userCannotSignEvent => 'This user cannot sign events.';

	/// en: 'Invalid event'
	String get invalidEvent => 'Invalid event';

	/// en: 'Event cannot be signed'
	String get eventCannotBeSigned => 'Event cannot be signed';

	/// en: 'Sign event'
	String get signEvent => 'Sign event';

	/// en: 'Sign'
	String get sign => 'Sign';

	/// en: 'Sign & publish'
	String get signPublish => 'Sign & publish';

	/// en: 'You are about to sign the following event'
	String get signEventDes => 'You are about to sign the following event';

	/// en: 'Automatic signing'
	String get enableAutomaticSigning => 'Automatic signing';

	/// en: 'Tools'
	String get tools => 'Tools';

	/// en: 'Search for smart widgets'
	String get searchSmartWidgets => 'Search for smart widgets';

	/// en: 'No tools available'
	String get noToolsAvailable => 'No tools available';

	/// en: 'Under maintenance'
	String get underMaintenance => 'Under maintenance';

	/// en: 'Smart Widget is down for maintenance. We're fixing it up and will have it back soon!'
	String get smartWidgetMaintenance => 'Smart Widget is down for maintenance. We\'re fixing it up and will have it back soon!';

	/// en: 'My saved tools'
	String get mySavedTools => 'My saved tools';

	/// en: 'Available tools'
	String get availableTools => 'Available tools';

	/// en: 'Remove'
	String get remove => 'Remove';

	/// en: 'You have no tools'
	String get youHaveNoTools => 'You have no tools';

	/// en: 'Discover published tools to help you with your content creation'
	String get discoverTools => 'Discover published tools to help you with your content creation';

	/// en: 'Add widget tools'
	String get addWidgetTools => 'Add widget tools';

	/// en: 'Widget search'
	String get widgetSearch => 'Widget search';

	/// en: 'searching for published smart widgets and what people made'
	String get widgetSearchDesc => 'searching for published smart widgets and what people made';

	/// en: 'Get inspired'
	String get getInspired => 'Get inspired';

	/// en: 'ask our AI to help you build your smart widget'
	String get getInspirtedDesc => 'ask our AI to help you build your smart widget';

	/// en: 'Try out different methods of searching'
	String get trySearch => 'Try out different methods of searching';

	/// en: 'Type / for commands'
	String get typeForCommands => 'Type / for commands';

	/// en: 'Load more'
	String get loadMore => 'Load more';

	/// en: 'Search for: {{name}}'
	String searchingFor({required Object name}) => 'Search for: ${name}';

	/// en: 'Playground'
	String get playground => 'Playground';

	/// en: 'Type keywords (ie: Keyword1, Keyword2..)'
	String get typeKeywords => 'Type keywords (ie: Keyword1, Keyword2..)';

	/// en: 'Gossip model'
	String get enableGossip => 'Gossip model';

	/// en: 'Gossip model is disabled by default. You can enable it, in Settings, under Content moderation.'
	String get enableGossipDesc => 'Gossip model is disabled by default. You can enable it, in Settings, under Content moderation.';

	/// en: 'Use external browser'
	String get enableExternalBrowser => 'Use external browser';

	/// en: 'Restart the app for the action to take effect'
	String get restartAppTakeEffect => 'Restart the app for the action to take effect';

	/// en: 'Tips'
	String get tips => 'Tips';

	/// en: 'Docs'
	String get docs => 'Docs';

	/// en: 'Try out your mini-app with hands-on, interactive testing.'
	String get tryMiniApp => 'Try out your mini-app with hands-on, interactive testing.';

	/// en: 'Explore our repos or check our Smart Widgets docs.'
	String get exploreOurRepos => 'Explore our repos or check our Smart Widgets docs.';

	/// en: 'We're bringing AI!'
	String get bringAi => 'We\'re bringing AI!';

	/// en: 'We're crafting an AI assistant to streamline your work with programmable widgets and mini-app development—keep an eye out!'
	String get bringAiDesc => 'We\'re crafting an AI assistant to streamline your work with programmable widgets and mini-app development—keep an eye out!';

	/// en: '{{number}} note(s)'
	String notesCount({required Object number}) => '${number} note(s)';

	/// en: '{{number}} content'
	String mixedContentCount({required Object number}) => '${number} content';

	/// en: 'No suited app can be found to open the exported file'
	String get noApp => 'No suited app can be found to open the exported file';

	/// en: '& {{number}} other(s)'
	String andMore({required Object number}) => '& ${number} other(s)';

	/// en: 'Add filter'
	String get addFilter => 'Add filter';

	/// en: 'Entitle of filter'
	String get entitleFilter => 'Entitle of filter';

	/// en: 'Included words'
	String get includedWords => 'Included words';

	/// en: 'Excluded words'
	String get excludedWords => 'Excluded words';

	/// en: 'Hide sensitive content'
	String get hideSensitiveContent => 'Hide sensitive content';

	/// en: 'Must include thumbnail'
	String get mustIncludeThumbnail => 'Must include thumbnail';

	/// en: 'For articles'
	String get forArticles => 'For articles';

	/// en: 'For videos'
	String get forVideos => 'For videos';

	/// en: 'For curations'
	String get forCurations => 'For curations';

	/// en: 'Content minimum words count'
	String get articleMinWords => 'Content minimum words count';

	/// en: 'Show only articles with media'
	String get showOnlyArticleMedia => 'Show only articles with media';

	/// en: 'Show only notes with media'
	String get showOnlyNotesMedia => 'Show only notes with media';

	/// en: 'Curations type'
	String get curationsType => 'Curations type';

	/// en: 'Minimum items count'
	String get minItemCount => 'Minimum items count';

	/// en: 'Add a proper word'
	String get addWord => 'Add a proper word';

	/// en: 'Make sure the word is not in the included words'
	String get wordNotInIncluded => 'Make sure the word is not in the included words';

	/// en: 'Make sure the word is not in the excluded words'
	String get wordNotInExcluded => 'Make sure the word is not in the excluded words';

	/// en: 'Field required'
	String get fieldRequired => 'Field required';

	/// en: 'Filter has been added'
	String get filterAdded => 'Filter has been added';

	/// en: 'Filter has been updated'
	String get filterUpdated => 'Filter has been updated';

	/// en: 'Filter has been deleted'
	String get filterDeleted => 'Filter has been deleted';

	/// en: 'Filters'
	String get filters => 'Filters';

	/// en: 'Content feed'
	String get contentFeed => 'Content feed';

	/// en: 'Community feed'
	String get communityFeed => 'Community feed';

	/// en: 'Relays feed'
	String get relaysFeed => 'Relays feed';

	/// en: 'Marketplace feed'
	String get marketplaceFeed => 'Marketplace feed';

	/// en: 'Add your preferred feed'
	String get addYourFeed => 'Add your preferred feed';

	/// en: 'My list'
	String get myList => 'My list';

	/// en: 'All free feeds'
	String get allFreeFeeds => 'All free feeds';

	/// en: 'No relays are present'
	String get noRelays => 'No relays are present';

	/// en: 'Add your relay list to enjoy a clean and custom feed'
	String get addRelays => 'Add your relay list to enjoy a clean and custom feed';

	/// en: 'Adjust your feed list'
	String get adjustYourFeedList => 'Adjust your feed list';

	/// en: 'Add relay url'
	String get addRelayUrl => 'Add relay url';

	/// en: 'At least one feed option should be enabled'
	String get feedOptionEnabled => 'At least one feed option should be enabled';

	/// en: 'Feed set has been updated'
	String get feedSetUpdate => 'Feed set has been updated';

	/// en: 'Global'
	String get global => 'Global';

	/// en: 'From network'
	String get fromNetwork => 'From network';

	/// en: 'Top'
	String get top => 'Top';

	/// en: 'Your current feed is based on someone else's following list, start following people to tailor your feed on your preference'
	String get showFollowingList => 'Your current feed is based on someone else\'s following list, start following people to tailor your feed on your preference';

	/// en: 'From'
	String get from => 'From';

	/// en: 'To'
	String get to => 'To';

	/// en: 'dd/MM/yyyy'
	String get dayMonthYear => 'dd/MM/yyyy';

	/// en: ''From' date must be earlier than 'To' date'
	String get fromDateMessage => '\'From\' date must be earlier than \'To\' date';

	/// en: ''To' date must be later than 'From' date'
	String get toDateMessage => '\'To\' date must be later than \'From\' date';

	/// en: 'No results'
	String get noResults => 'No results';

	/// en: 'It looks like you're applying a custom filter, please adjust the parameters and dates to acquire more data'
	String get noResultsFilterMessage => 'It looks like you\'re applying a custom filter, please adjust the parameters and dates to acquire more data';

	/// en: 'Nothing was found, please change your content source or apply different filter params'
	String get noResultsNoFilterMessage => 'Nothing was found, please change your content source or apply different filter params';

	/// en: 'Add to notes'
	String get addToNotes => 'Add to notes';

	/// en: 'Add to discover'
	String get addToDiscover => 'Add to discover';

	/// en: 'Share relay content'
	String get shareRelayContent => 'Share relay content';

	/// en: 'Share relay URL'
	String get shareRelayUrl => 'Share relay URL';

	/// en: 'Basic'
	String get basic => 'Basic';

	/// en: 'Private messages'
	String get privateMessages => 'Private messages';

	/// en: 'Push notifications'
	String get pushNotifications => 'Push notifications';

	/// en: 'Replies view'
	String get repliesView => 'Replies view';

	/// en: 'Thread'
	String get threadView => 'Thread';

	/// en: 'Box'
	String get boxView => 'Box';

	/// en: 'View as'
	String get viewAs => 'View as';

	/// en: 'Feed settings'
	String get feedSettings => 'Feed settings';

	/// en: 'This note is hidden due to the current applied filter.'
	String get appliedFilterDesc => 'This note is hidden due to the current applied filter.';

	/// en: 'Show note'
	String get showNote => 'Show note';

	/// en: 'All media'
	String get allMedia => 'All media';

	/// en: 'Search in Nostr'
	String get searchInNostr => 'Search in Nostr';

	/// en: 'Find people, notes & content'
	String get findPeopleContent => 'Find people, notes & content';

	/// en: 'Active service'
	String get activeService => 'Active service';

	/// en: 'Regular servers'
	String get regularServers => 'Regular servers';

	/// en: 'BLOSSOM servers'
	String get blossomServers => 'BLOSSOM servers';

	/// en: 'Mirror all servers'
	String get mirrorAllServer => 'Mirror all servers';

	/// en: 'Main server'
	String get mainServer => 'Main server';

	/// en: 'Select'
	String get select => 'Select';

	/// en: 'No server found'
	String get noServerFound => 'No server found';

	/// en: 'Server already exists on your list'
	String get serverExists => 'Server already exists on your list';

	/// en: 'Invalid url format'
	String get invalidUrl => 'Invalid url format';

	/// en: 'Server path'
	String get serverPath => 'Server path';

	/// en: 'Error occured while adding blossom server'
	String get errorAddingBlossom => 'Error occured while adding blossom server';

	/// en: 'Error occured while selecting blossom server'
	String get errorSelectBlossom => 'Error occured while selecting blossom server';

	/// en: 'Error occured while deleting blossom server'
	String get errorDeleteBlossom => 'Error occured while deleting blossom server';

	/// en: 'Web of trust configuration'
	String get wotConfig => 'Web of trust configuration';

	/// en: 'web of trust'
	String get wot => 'web of trust';

	/// en: 'Web of trust threshold'
	String get wotThreshold => 'Web of trust threshold';

	/// en: 'Post actions'
	String get postActions => 'Post actions';

	/// en: 'Enabled for'
	String get enabledFor => 'Enabled for';

	/// en: 'Private messages relays are not configured!'
	String get dmRelayTitle => 'Private messages relays are not configured!';

	/// en: 'Update your relays list accordingly. '
	String get dmRelayDesc => 'Update your relays list accordingly. ';

	/// en: 'You follow'
	String get youFollow => 'You follow';

	/// en: 'You have exceeded your daily quota limit'
	String get quotaLimit => 'You have exceeded your daily quota limit';

	/// en: 'Always use external wallet zaps'
	String get alwaysUseExternal => 'Always use external wallet zaps';

	/// en: 'Use an external Lightning wallet app instead of YakiHonne's built-in wallet for all zap transactions.'
	String get alwaysUseExternalDesc => 'Use an external Lightning wallet app instead of YakiHonne\'s built-in wallet for all zap transactions.';

	/// en: 'Unreachable external wallet'
	String get unreachableExternalWallet => 'Unreachable external wallet';

	/// en: 'Your keys are stored securely on your device and never shared with us or anyone else.'
	String get secureStorageDesc => 'Your keys are stored securely on your device and never shared with us or anyone else.';

	/// en: 'Safe to share - this identifies you on Nostr.'
	String get pubkeySharedDesc => 'Safe to share - this identifies you on Nostr.';

	/// en: 'Keep private - backup securely to access your account elsewhere.'
	String get privKeyDesc => 'Keep private - backup securely to access your account elsewhere.';

	/// en: 'Manage your Nostr keys for network identity, event signing, and post authentication.'
	String get settingsKeysDesc => 'Manage your Nostr keys for network identity, event signing, and post authentication.';

	/// en: 'Configure Nostr relay connections for storing and distributing events.'
	String get settingsRelaysDesc => 'Configure Nostr relay connections for storing and distributing events.';

	/// en: 'Personalize your YakiHonne feed display, gestures, previews, and preferences for better Nostr experience.'
	String get settingsCustomizationDesc => 'Personalize your YakiHonne feed display, gestures, previews, and preferences for better Nostr experience.';

	/// en: 'Control notifications for messages, mentions, reactions, and other Nostr events.'
	String get settingsNotificationsDesc => 'Control notifications for messages, mentions, reactions, and other Nostr events.';

	/// en: 'Control content interactions, privacy settings, media handling, and messaging preferences on Nostr.'
	String get settingsContentDesc => 'Control content interactions, privacy settings, media handling, and messaging preferences on Nostr.';

	/// en: 'Choose your preferred language for YakiHonne interface and content translation.'
	String get settingsLanguageDesc => 'Choose your preferred language for YakiHonne interface and content translation.';

	/// en: 'Connect and manage Bitcoin Lightning wallets for sending/receiving zaps with customizable amounts and external integration.'
	String get settingsWalletDesc => 'Connect and manage Bitcoin Lightning wallets for sending/receiving zaps with customizable amounts and external integration.';

	/// en: 'Customize YakiHonne's visual appearance to match your preferences and viewing comfort.'
	String get settingsAppearanceDesc => 'Customize YakiHonne\'s visual appearance to match your preferences and viewing comfort.';

	/// en: 'Manage app performance monitoring, error reporting, and storage optimization for smooth operation.'
	String get settingsCacheDesc => 'Manage app performance monitoring, error reporting, and storage optimization for smooth operation.';

	/// en: 'Quickly add a new relay by entering its URL.'
	String get addQuickRelayDesc => 'Quickly add a new relay by entering its URL.';

	/// en: 'Fewer stable relays = better performance and faster syncing.'
	String get fewerRelays => 'Fewer stable relays = better performance and faster syncing.';

	/// en: 'Green dots show active connections.'
	String get greenDotsDesc => 'Green dots show active connections.';

	/// en: 'Red dots show offline relays.'
	String get redDotsDesc => 'Red dots show offline relays.';

	/// en: 'Grey dots show pending relays.'
	String get greyDotsDesc => 'Grey dots show pending relays.';

	/// en: 'Choose reply display style (Box or Thread) and manage suggestion preferences for people, content, and interests.'
	String get homeFeedCustomDesc => 'Choose reply display style (Box or Thread) and manage suggestion preferences for people, content, and interests.';

	/// en: 'Choose what happens when you long-press while creating posts (currently set to Note).'
	String get NewPostDesc => 'Choose what happens when you long-press while creating posts (currently set to Note).';

	/// en: 'Show user profile previews when tapping usernames in your feed.'
	String get profilePreviewDesc => 'Show user profile previews when tapping usernames in your feed.';

	/// en: 'Automatically minimize long posts to keep your feed clean and readable.'
	String get collapseNoteDesc => 'Automatically minimize long posts to keep your feed clean and readable.';

	/// en: 'Get instant alerts on your device. Privacy-focused using secure FCM and APNS protocols'
	String get pushNotificationsDesc => 'Get instant alerts on your device. Privacy-focused using secure FCM and APNS protocols';

	/// en: 'Get alerted for new direct messages and private conversations.'
	String get privateMessagesDesc => 'Get alerted for new direct messages and private conversations.';

	/// en: 'Get notified when people you follow post new content.'
	String get followingDesc => 'Get notified when people you follow post new content.';

	/// en: 'Get alerted when someone mentions you or replies to your posts.'
	String get mentionsDesc => 'Get alerted when someone mentions you or replies to your posts.';

	/// en: 'Get alerted when someone shares or reposts your content.'
	String get repostsDesc => 'Get alerted when someone shares or reposts your content.';

	/// en: 'Get notified when some likes or react to your posts.'
	String get reactionsDesc => 'Get notified when some likes or react to your posts.';

	/// en: 'Get notified when you receive Bitcoin tips (zaps) on your posts.'
	String get zapDesc => 'Get notified when you receive Bitcoin tips (zaps) on your posts.';

	/// en: 'View and manage users you've blocked from appearing in your feed.'
	String get muteListDesc => 'View and manage users you\'ve blocked from appearing in your feed.';

	/// en: 'Choose which service uploads your images and media files.'
	String get mediaUploaderDesc => 'Choose which service uploads your images and media files.';

	/// en: 'Automatically sign events requested by mini apps (action/tool smart widgets) without manual confirmation each time.'
	String get autoSignDesc => 'Automatically sign events requested by mini apps (action/tool smart widgets) without manual confirmation each time.';

	/// en: 'Sophisticated relay management that automatically finds your followees' posts across different relays while minimizing connections and adapting to offline relays.'
	String get gossipDesc => 'Sophisticated relay management that automatically finds your followees\' posts across different relays while minimizing connections and adapting to offline relays.';

	/// en: 'Open links in your default browser app instead of the built-in browser.'
	String get useExternalBrowsDesc => 'Open links in your default browser app instead of the built-in browser.';

	/// en: 'Use the latest private messaging standard (NIP-17) with advanced encryption. Disable to use the older NIP-4 format for compatibility.'
	String get secureDmDesc => 'Use the latest private messaging standard (NIP-17) with advanced encryption. Disable to use the older NIP-4 format for compatibility.';

	/// en: 'A decentralized trust mechanism using social attestations to establish reputation within the Nostr protocol.'
	String get wotConfigDesc => 'A decentralized trust mechanism using social attestations to establish reputation within the Nostr protocol.';

	/// en: 'Choose the language for YakiHonne's interface, menus, and buttons.'
	String get appLangDesc => 'Choose the language for YakiHonne\'s interface, menus, and buttons.';

	/// en: 'Select translation service for posts in foreign languages.'
	String get contentTransDesc => 'Select translation service for posts in foreign languages.';

	/// en: 'Your current translation plan tier and usage limits.'
	String get planDesc => 'Your current translation plan tier and usage limits.';

	/// en: 'Add and organize your Lightning wallets for sending and receiving Bitcoin zaps on Nostr.'
	String get manageWalletsDesc => 'Add and organize your Lightning wallets for sending and receiving Bitcoin zaps on Nostr.';

	/// en: 'Set the default Bitcoin amount (in sats) when sending quick zaps to posts.'
	String get defaultZapDesc => 'Set the default Bitcoin amount (in sats) when sending quick zaps to posts.';

	/// en: 'One tap sends default amount instantly. Double tap opens zap options (amount, wallet, message). When disabled, double tap sends default amount.'
	String get enableZapDesc => 'One tap sends default amount instantly. Double tap opens zap options (amount, wallet, message). When disabled, double tap sends default amount.';

	/// en: 'Use an external Lightning wallet app instead of YakiHonne's built-in wallet for all zap transactions.'
	String get externalWalletDesc => 'Use an external Lightning wallet app instead of YakiHonne\'s built-in wallet for all zap transactions.';

	/// en: 'Adjust text size throughout the app for better readability - use the slider to make text larger or smaller.'
	String get fontSizeDesc => 'Adjust text size throughout the app for better readability - use the slider to make text larger or smaller.';

	/// en: 'Switch between light and dark mode to customize the app's visual appearance.'
	String get appThemeDesc => 'Switch between light and dark mode to customize the app\'s visual appearance.';

	/// en: 'Anonymous crash reporting and app analytics to help improve performance and fix bugs. We use Umami analytics to improve your experience. Opt out anytime.'
	String get crashlyticsDesc => 'Anonymous crash reporting and app analytics to help improve performance and fix bugs. We use Umami analytics to improve your experience. Opt out anytime.';

	/// en: 'Display general content recommendations in your feed.'
	String get showSuggDesc => 'Display general content recommendations in your feed.';

	/// en: 'Show recommended users to follow based on your activity.'
	String get showSuggPeople => 'Show recommended users to follow based on your activity.';

	/// en: 'Display recommended posts and articles in your feed.'
	String get showSuggContent => 'Display recommended posts and articles in your feed.';

	/// en: 'Show topic and interest recommendations for discovery.'
	String get showSuggInterests => 'Show topic and interest recommendations for discovery.';

	/// en: 'We strive to make the best out of Nostr, Support us below or send us your valuable feed: zap, dms, github.'
	String get striveToMake => 'We strive to make the best out of Nostr, Support us below or send us your valuable feed: zap, dms, github.';

	/// en: 'You either rejected or you are already connected with amber'
	String get errorAmber => 'You either rejected or you are already connected with amber';

	/// en: 'You should at least leave one relay connected'
	String get useOneRelay => 'You should at least leave one relay connected';

	/// en: 'Automatic cache purge'
	String get automaticPurge => 'Automatic cache purge';

	/// en: 'Auto-clear app cache when it reaches 2GB. Maintains performance and prevents excessive storage usage.'
	String get automaticPurgeDesc => 'Auto-clear app cache when it reaches 2GB. Maintains performance and prevents excessive storage usage.';

	/// en: 'Custom services'
	String get customServices => 'Custom services';

	/// en: 'Default services'
	String get defaultServices => 'Default services';

	/// en: 'Add service'
	String get addService => 'Add service';

	/// en: 'Available custom services added by you.'
	String get customServicesDesc => 'Available custom services added by you.';

	/// en: 'Url required'
	String get urlRequired => 'Url required';

	/// en: 'Service has been added'
	String get serviceAdded => 'Service has been added';

	/// en: 'Show raw event'
	String get showRawEvent => 'Show raw event';

	/// en: 'Raw event data'
	String get rawEventData => 'Raw event data';

	/// en: 'Raw event data was copied! 👏'
	String get copyRawEventData => 'Raw event data was copied! 👏';

	/// en: 'Kind'
	String get kind => 'Kind';

	/// en: 'Short note'
	String get shortNote => 'Short note';

	/// en: 'Posted on'
	String get postedOnDate => 'Posted on';

	/// en: '... show more'
	String get showMore => '... show more';

	/// en: 'This account has been deleted and can no longer be accessed.'
	String get accountDeleted => 'This account has been deleted and can no longer be accessed.';

	/// en: 'OK'
	String get ok => 'OK';

	/// en: 'Redeem'
	String get redeem => 'Redeem';

	/// en: 'Redeem code'
	String get redeemCode => 'Redeem code';

	/// en: 'Redeem & Earn'
	String get redeemAndEarn => 'Redeem & Earn';

	/// en: 'Redeeming failed'
	String get redeemingFailed => 'Redeeming failed';

	/// en: 'Redeeming code in progress...'
	String get redeemInProgress => 'Redeeming code in progress...';

	/// en: 'Enter your code to redeem it'
	String get redeemCodeDesc => 'Enter your code to redeem it';

	/// en: 'Missing code'
	String get missingCode => 'Missing code';

	/// en: 'Missing pubkey'
	String get missingPubkey => 'Missing pubkey';

	/// en: 'Invalid pubkey'
	String get invalidPubkey => 'Invalid pubkey';

	/// en: 'Missing lightning address'
	String get missingLightningAddress => 'Missing lightning address';

	/// en: 'Code not found'
	String get codeNotFound => 'Code not found';

	/// en: 'Redeem code is required'
	String get redeemCodeRequired => 'Redeem code is required';

	/// en: 'Redeem code is invalid'
	String get redeemCodeInvalid => 'Redeem code is invalid';

	/// en: 'Your code is being redeemed. If it doesn't complete successfully, please try again shortly.'
	String get codeBeingRedeemed => 'Your code is being redeemed. If it doesn\'t complete successfully, please try again shortly.';

	/// en: 'Code has been successfully redeemed'
	String get redeemCodeSuccess => 'Code has been successfully redeemed';

	/// en: 'Could not redeem the code, please try again later.'
	String get redeemFailed => 'Could not redeem the code, please try again later.';

	/// en: 'Code has already been redeemed'
	String get codeAlreadyRedeemed => 'Code has already been redeemed';

	/// en: '+{{amount}} sats earned.'
	String satsEarned({required Object amount}) => '+${amount} sats earned.';

	/// en: 'Select receiving wallet'
	String get selectReceivingWallet => 'Select receiving wallet';

	/// en: 'Claim free sats with YakiHonne redeemable codes — simply enter your code and boost your balance instantly.'
	String get redeemCodeMessage => 'Claim free sats with YakiHonne redeemable codes — simply enter your code and boost your balance instantly.';

	/// en: 'Scan code'
	String get scanCode => 'Scan code';

	/// en: 'Enter code'
	String get enterCode => 'Enter code';

	/// en: 'Error occured while sharing media'
	String get errorSharingMedia => 'Error occured while sharing media';

	/// en: 'Open'
	String get open => 'Open';

	/// en: 'Open URL'
	String get openUrl => 'Open URL';

	/// en: 'Do you want to open "{{url}}"?'
	String openUrlDesc({required Object url}) => 'Do you want to open "${url}"?';

	/// en: 'Open url prompt'
	String get openUrlPrompt => 'Open url prompt';

	/// en: 'A safety prompt that displays the full URL before opening it in your browser.'
	String get openUrlPromptDesc => 'A safety prompt that displays the full URL before opening it in your browser.';

	/// en: 'Waiting for network...'
	String get waitingForNetwork => 'Waiting for network...';

	/// en: 'What's new'
	String get whatsNew => 'What\'s new';

	/// en: 'App custom'
	String get appCustom => 'App custom';

	/// en: 'Poll'
	String get poll => 'Poll';

	/// en: 'Pending events'
	String get pendingEvents => 'Pending events';

	/// en: 'Pending events are created while offline or with poor connection. They'll be automatically sent when your internet connection is restored.'
	String get pendingEventsDesc => 'Pending events are created while offline or with poor connection. They\'ll be automatically sent when your internet connection is restored.';

	/// en: 'Single column feed'
	String get singleColumnFeed => 'Single column feed';

	/// en: 'Show the home feed as a single wide column for better readability.'
	String get singleColumnFeedDesc => 'Show the home feed as a single wide column for better readability.';

	/// en: 'Waiting for payment'
	String get waitingPayment => 'Waiting for payment';

	/// en: 'Copy id'
	String get copyId => 'Copy id';

	/// en: 'Id was copied! 👏'
	String get idCopied => 'Id was copied! 👏';

	/// en: 'Republish'
	String get republish => 'Republish';

	/// en: 'You should at least choose one relay to republish to.'
	String get useRelayRepublish => 'You should at least choose one relay to republish to.';

	/// en: 'Event has been republished successfully!'
	String get republishSucces => 'Event has been republished successfully!';

	/// en: 'Error occured while republishing event'
	String get errorRepublishEvent => 'Error occured while republishing event';

	/// en: 'Remote signer'
	String get remoteSigner => 'Remote signer';

	/// en: 'Amber'
	String get amber => 'Amber';

	/// en: 'Use the below URL to connect to your bunker'
	String get useUrlBunker => 'Use the below URL to connect to your bunker';

	/// en: 'Or'
	String get or => 'Or';

	/// en: 'Messages are disabled'
	String get messagesDisabled => 'Messages are disabled';

	/// en: 'You are connected with a remote signer. Direct messages may contain large amounts of data and might not work properly. For the best experience, please use a local signer to enable direct messaging.'
	String get messagesDisabledDesc => 'You are connected with a remote signer. Direct messages may contain large amounts of data and might not work properly. For the best experience, please use a local signer to enable direct messaging.';

	/// en: 'Shared on {{date}}'
	String sharedOn({required Object date}) => 'Shared on ${date}';

	/// en: 'Share as image'
	String get shareAsImage => 'Share as image';

	/// en: 'View options'
	String get viewOptions => 'View options';

	/// en: 'Feed customization'
	String get feedCustomization => 'Feed customization';

	/// en: 'Default reaction'
	String get defaultReaction => 'Default reaction';

	/// en: 'Set a default reaction to react to posts.'
	String get defaultReactionDesc => 'Set a default reaction to react to posts.';

	/// en: 'Enable one tap reaction'
	String get oneTapReaction => 'Enable one tap reaction';

	/// en: 'One tap react with the default reaction instantly. Double tap opens emojis list to choose from. When disabled, double tap sends default reaction'
	String get oneTapReactionDesc => 'One tap react with the default reaction instantly. Double tap opens emojis list to choose from. When disabled, double tap sends default reaction';

	/// en: 'Sending to'
	String get sendingTo => 'Sending to';

	/// en: 'Your followings list and friends will appear here for faster sharing experience'
	String get shareEmptyUsers => 'Your followings list and friends will appear here for faster sharing experience';

	/// en: 'Publish only to'
	String get publishOnly => 'Publish only to';

	/// en: 'Protected event'
	String get protectedEvent => 'Protected event';

	/// en: 'A protected event is an event that only its author can republish. This keeps the content authentic and prevents others from copying or reissuing it.'
	String get protectedEventDesc => 'A protected event is an event that only its author can republish. This keeps the content authentic and prevents others from copying or reissuing it.';

	/// en: 'Browse relay'
	String get browseRelay => 'Browse relay';

	/// en: 'Add favorite'
	String get addFavorite => 'Add favorite';

	/// en: 'Remove favorite'
	String get removeFavorite => 'Remove favorite';

	/// en: 'Collections'
	String get collections => 'Collections';

	/// en: 'Online'
	String get online => 'Online';

	/// en: 'Offline'
	String get offline => 'Offline';

	/// en: 'Network'
	String get network => 'Network';

	/// en: 'Followed by {{number}}'
	String followedBy({required Object number}) => 'Followed by ${number}';

	/// en: 'Favored by {{number}}'
	String favoredBy({required Object number}) => 'Favored by ${number}';

	/// en: 'Required authentication'
	String get requiredAuthentication => 'Required authentication';

	/// en: 'Relay orbits'
	String get relayOrbits => 'Relay orbits';

	/// en: 'Browse and explore relay feeds'
	String get relayOrbitsDesc => 'Browse and explore relay feeds';

	/// en: 'People'
	String get people => 'People';

	/// en: 'You're not connected'
	String get youNotConnected => 'You\'re not connected';

	/// en: 'Log in to your account to browse your network relays'
	String get youNotConnectedDesc => 'Log in to your account to browse your network relays';

	/// en: 'Checking relay connectivity'
	String get checkingRelayConnectivity => 'Checking relay connectivity';

	/// en: 'Unreachable relay'
	String get unreachableRelay => 'Unreachable relay';

	/// en: 'Engage to expand'
	String get engageWithUsers => 'Engage to expand';

	/// en: 'Engaging with more users helps you discover new relays and grow your relay list for a richer, more connected experience.'
	String get engageWithUsersDesc => 'Engaging with more users helps you discover new relays and grow your relay list for a richer, more connected experience.';

	/// en: 'Loading chat history...'
	String get loadingChatHistory => 'Loading chat history...';

	/// en: 'Content actions order'
	String get contentActionsOrder => 'Content actions order';

	/// en: 'Easily rearrange your post interactions to match your preferred order.'
	String get contentActionsOrderDesc => 'Easily rearrange your post interactions to match your preferred order.';

	/// en: 'Quotes'
	String get quotes => 'Quotes';

	/// en: 'Event loading...'
	String get eventLoading => 'Event loading...';

	/// en: 'Load messages'
	String get loadMessages => 'Load messages';

	/// en: 'Messages Not Loaded'
	String get messagesNotLoaded => 'Messages Not Loaded';

	/// en: 'Messages are not loaded due to using a local remote signer, if you wish to load them, please click the button below.'
	String get messagesNotLoadedDesc => 'Messages are not loaded due to using a local remote signer, if you wish to load them, please click the button below.';

	/// en: 'Note loading...'
	String get noteLoading => 'Note loading...';

	/// en: 'Hide non-followed media'
	String get hideNonFollowedMedia => 'Hide non-followed media';

	/// en: 'Automatically hide images & videos from non-followed users until you tap to reveal.'
	String get hideNonFollowedMediaDesc => 'Automatically hide images & videos from non-followed users until you tap to reveal.';

	/// en: 'Click to view'
	String get clickToView => 'Click to view';

	/// en: 'Relays feed list is empty'
	String get relayFeedListEmpty => 'Relays feed list is empty';

	/// en: 'Add more relays to your list to enjoy a tailored feed.'
	String get relayFeedListEmptyDesc => 'Add more relays to your list to enjoy a tailored feed.';

	/// en: 'Add relays'
	String get addRelay => 'Add relays';

	/// en: 'Hidden content'
	String get hiddenContent => 'Hidden content';

	/// en: 'We've hidden this content because you don't follow this account.'
	String get hiddenContentDesc => 'We\'ve hidden this content because you don\'t follow this account.';

	/// en: 'Enabled actions'
	String get enabledActions => 'Enabled actions';

	/// en: 'No enabled actions available.'
	String get enabledActionsDesc => 'No enabled actions available.';

	/// en: 'Fetching notification event'
	String get fetchingNotificationEvent => 'Fetching notification event';

	/// en: 'Notification event not found'
	String get notificationEventNotFound => 'Notification event not found';

	/// en: 'Fiat currency'
	String get fiatCurrency => 'Fiat currency';

	/// en: 'Convert sats into your selected fiat currency to better understand their value'
	String get fiatCurrencyDesc => 'Convert sats into your selected fiat currency to better understand their value';

	/// en: 'Link preview'
	String get linkPreview => 'Link preview';

	/// en: 'Toggle to display or hide previews for shared links in posts.'
	String get linkPreviewDesc => 'Toggle to display or hide previews for shared links in posts.';

	/// en: 'Mute thread'
	String get muteThread => 'Mute thread';

	/// en: 'Your are about to mute the thread, do you wish to proceed?'
	String get muteThreadDesc => 'Your are about to mute the thread, do you wish to proceed?';

	/// en: 'Unmute thread'
	String get unmuteThread => 'Unmute thread';

	/// en: 'Your are about to unmute the thread, do you wish to proceed?'
	String get unmuteThreadDesc => 'Your are about to unmute the thread, do you wish to proceed?';

	/// en: 'Thread has been muted'
	String get threadMuted => 'Thread has been muted';

	/// en: 'Thread has been unmuted'
	String get threadUnmuted => 'Thread has been unmuted';

	/// en: 'No muted events have been found.'
	String get noMutedEventsFound => 'No muted events have been found.';

	/// en: 'Edit code'
	String get editCode => 'Edit code';

	/// en: 'Preview code'
	String get previewCode => 'Preview code';

	/// en: 'Live code'
	String get liveCode => 'Live code';

	/// en: 'Tag'
	String get tag => 'Tag';

	/// en: 'Quick connect to relay'
	String get quickConnectRelay => 'Quick connect to relay';

	/// en: 'Explore search relays'
	String get exploreSearchRelays => 'Explore search relays';

	/// en: 'Navigate & add active search relays'
	String get navigateToSearch => 'Navigate & add active search relays';

	/// en: 'Error occured while downloading the video'
	String get errorSavingVideo => 'Error occured while downloading the video';

	/// en: 'Video has been downloaded to your gallery'
	String get saveVideoGallery => 'Video has been downloaded to your gallery';

	/// en: 'Downloading video'
	String get downloadingVideo => 'Downloading video';

	/// en: 'Primary color'
	String get primaryColor => 'Primary color';

	/// en: 'Pick the accent color that shapes the app's overall mood and highlights key elements.'
	String get primaryColorDesc => 'Pick the accent color that shapes the app\'s overall mood and highlights key elements.';

	/// en: 'Single'
	String get single => 'Single';

	/// en: 'Sets'
	String get sets => 'Sets';

	/// en: 'Select from your relay sets'
	String get selectFromRelaySets => 'Select from your relay sets';

	/// en: 'Favorite relays'
	String get favoriteRelays => 'Favorite relays';

	/// en: 'Favorite relay sets'
	String get favoriteRelaySets => 'Favorite relay sets';

	/// en: 'Add relay set'
	String get addRelaySet => 'Add relay set';

	/// en: 'Update relay set'
	String get updateRelaySet => 'Update relay set';

	/// en: 'Relay set created'
	String get relaySetCreated => 'Relay set created';

	/// en: 'Error occured while creating relay set'
	String get errorOnCreatingRelaySet => 'Error occured while creating relay set';

	/// en: 'Error occured while updating relay set'
	String get errorOnUpdatingRelaySet => 'Error occured while updating relay set';

	/// en: 'Relay set deleted'
	String get relaySetDeleted => 'Relay set deleted';

	/// en: 'Error occured while deleting relay set'
	String get errorDeletingRelaySet => 'Error occured while deleting relay set';

	/// en: '{{number}} relays'
	String relaysNumber({required Object number}) => '${number} relays';

	/// en: 'Relay set not found'
	String get relaySetNotFound => 'Relay set not found';

	/// en: 'Relay set is missing or has been deleted.'
	String get relaySetNotFoundDesc => 'Relay set is missing or has been deleted.';

	/// en: 'Saved relay sets'
	String get savedRelaySets => 'Saved relay sets';

	/// en: 'Relay sets'
	String get relaysets => 'Relay sets';

	/// en: 'Relay set list is empty'
	String get relaySetListEmpty => 'Relay set list is empty';

	/// en: 'Create relay sets to organize your relays for different purposes and scenarios.'
	String get relaySetListEmptyDesc => 'Create relay sets to organize your relays for different purposes and scenarios.';

	/// en: 'Favorite relays feed'
	String get favoriteRelaysFeed => 'Favorite relays feed';

	/// en: 'Max mentions'
	String get maxMentions => 'Max mentions';

	/// en: 'Hide notifications from notes with more than 10 user mentions.'
	String get maxMentionsDesc => 'Hide notifications from notes with more than 10 user mentions.';

	/// en: 'Media'
	String get media => 'Media';

	/// en: 'Pinned'
	String get pinned => 'Pinned';

	/// en: 'Pictures'
	String get pictures => 'Pictures';

	/// en: 'Unpin'
	String get unpin => 'Unpin';

	/// en: 'Pin'
	String get pin => 'Pin';

	/// en: '{{name}} published a picture'
	String userPublishedPicture({required Object name}) => '${name} published a picture';

	/// en: '{{name}} zapped your picture {{number}} sats'
	String userZappedYourPicture({required Object name, required Object number}) => '${name} zapped your picture ${number} sats';

	/// en: '{{name}} reacted {{reaction}} to your picture'
	String userReactedYourPicture({required Object name, required Object reaction}) => '${name} reacted ${reaction} to your picture';

	/// en: '{{name}} reacted {{reaction}} to a picture you were mentioned in'
	String userReactedPictureYouIn({required Object name, required Object reaction}) => '${name} reacted ${reaction} to a picture you were mentioned in';

	/// en: '{{name}} replied to your picture'
	String userRepliedYourPicture({required Object name}) => '${name} replied to your picture';

	/// en: '{{name}} replied to a picture you were mentioned in'
	String userRepliedPictureYouIn({required Object name}) => '${name} replied to a picture you were mentioned in';

	/// en: '{{name}} mentioned you in a picture'
	String userMentionedYouInPicture({required Object name}) => '${name} mentioned you in a picture';

	/// en: '{{name}} commented on your picture'
	String userCommentedYourPicture({required Object name}) => '${name} commented on your picture';

	/// en: '{{name}} commented on a picture you were mentioned in'
	String userCommentedPictureYouIn({required Object name}) => '${name} commented on a picture you were mentioned in';

	/// en: '{{name}} quoted your picture'
	String userQuotedYourPicture({required Object name}) => '${name} quoted your picture';

	/// en: '{{name}} quoted a picture you were mentioned in'
	String userQuotedPictureYouIn({required Object name}) => '${name} quoted a picture you were mentioned in';

	/// en: 'Either the app does not have permission to access the camera or there are no cameras available on this device.'
	String get cameraPermission => 'Either the app does not have permission to access the camera or there are no cameras available on this device.';

	/// en: 'Fetching picture...'
	String get fetchingPicture => 'Fetching picture...';

	/// en: 'Add description...'
	String get addDescription => 'Add description...';

	/// en: 'Uploading video...'
	String get uploadingVideo => 'Uploading video...';

	/// en: 'Upload thumbnail'
	String get uploadThumbnail => 'Upload thumbnail';

	/// en: 'Choose a proper thumbnail for your video'
	String get chooseThumbnailVideo => 'Choose a proper thumbnail for your video';

	/// en: 'Publishing...'
	String get publishing => 'Publishing...';

	/// en: 'Give me a catchy title'
	String get giveMeCatchyTitle => 'Give me a catchy title';
}

/// The flat map containing all translations for locale <en>.
/// Only for edge cases! For simple maps, use the map function of this library.
///
/// The Dart AOT compiler has issues with very large switch statements,
/// so the map is split into smaller functions (512 entries each).
extension on Translations {
	dynamic _flatMapFunction(String path) {
		return _flatMapFunction$0(path)
			?? _flatMapFunction$1(path)
			?? _flatMapFunction$2(path);
	}

	dynamic _flatMapFunction$0(String path) {
		return switch (path) {
			'addNewBookmark' => 'No bookmarks list can be found, try to add one!',
			'setBookmarkTitleDescription' => 'Set a title & a description for your bookmark list.',
			'title' => 'title',
			'description' => 'description',
			'descriptionOptional' => 'description (optional)',
			'bookmarkLists' => 'Bookmark lists',
			'submit' => 'submit',
			'addBookmarkList' => 'Add bookmark list',
			'submitBookmarkList' => 'Submit bookmark list',
			'next' => 'next',
			'saveDraft' => 'Save draft',
			'deleteDraft' => 'Delete draft',
			'publish' => 'publish',
			'smHaveOneWidget' => 'The smart widget should have atleast one component.',
			'smHaveTitle' => 'The smart widget should at least have a title',
			'whatsOnYourMind' => 'What\'s on your mind?',
			'sensitiveContent' => 'This is a sensitive content',
			'addYourTopics' => 'Add your topics',
			'article' => 'article',
			'articles' => 'articles',
			'video' => 'video',
			'videos' => 'videos',
			'curation' => 'curation',
			'curations' => 'curations',
			'thumbnailPreview' => 'Thumbnail preview',
			'selectAndUploadLocaleImage' => 'Select & upload a local image',
			'issueOccuredSelectingImage' => 'Issue occured while selecting the image.',
			'imageUploadHistory' => 'Images upload history',
			'noImageHistory' => 'No images history has been found',
			'cancel' => 'cancel',
			'uploadAndUse' => 'Upload & use',
			'publishRemoveDraft' => 'Publish and remove the draft',
			'clearChat' => 'Clear chat',
			'noDataFromGpt' => 'There are data to show from GPT.',
			'askMeSomething' => 'Ask me something!',
			'copy' => 'copy',
			'textSuccesfulyCopied' => 'Text successfully copied!',
			'insertText' => 'Insert text',
			'searchContentByTitle' => ({required Object type}) => 'Search ${type} by title',
			'noContentCanBeFound' => ({required Object type}) => 'No ${type} can be found',
			'noContentBelongToCuration' => ({required Object type}) => 'No ${type} belong to this curation',
			'byPerson' => ({required Object name}) => 'By ${name}',
			'allRelays' => 'All relays',
			'myArticles' => 'My articles',
			'myVideos' => 'My videos',
			'curationType' => 'Curation type',
			'update' => 'update',
			'invalidInvoiceLnurl' => 'Make sure to set a valid invoice or lnurl',
			'addValidUrl' => 'Make sure to add a valid url',
			'layoutCustomization' => 'Layout customization',
			'duoLayout' => 'Duolayout',
			'monoLayout' => 'MonoLayout',
			'warning' => 'warning',
			'switchToMonolayout' => 'You\'re switching to a mono layout whilst having elements on both sides, this will erase the container content, do you wish to proceed?',
			'erase' => 'erase',
			'textCustomization' => 'Text customization',
			'writeYourText' => 'Write your text',
			'size' => 'size',
			'weight' => 'weight',
			'color' => 'color',
			'videoCustomization' => 'Video customization',
			'videoUrl' => 'Video url',
			'zapPollCustomization' => 'Zap poll customization',
			'contentTextColor' => 'Content text color',
			'optionTextColor' => 'Option text color',
			'optionBackgroundColor' => 'Option background color',
			'fillColor' => 'Fill color',
			'imageCustomization' => 'Image customization',
			'imageUrl' => 'Image url',
			'imageAspectRatio' => 'Image aspect ratio',
			'buttonCustomization' => 'Button customization',
			'buttonText' => 'Button text',
			'type' => 'type',
			'useInvoice' => 'Use invoice',
			'invoice' => 'invoice',
			'lightningAddress' => 'Lightning address',
			'selectUserToZap' => 'Select a user to zap (optional)',
			'zapPollNevent' => 'Zap poll nevent',
			'textColor' => 'Text color',
			'buttonColor' => 'Button color',
			'url' => 'Url',
			'invoiceOrLN' => 'Invoice or Lightning address',
			'youtubeUrl' => 'Youtube url',
			'telegramUrl' => 'Telegram Url',
			'xUrl' => 'X url',
			'discordUrl' => 'Discord url',
			'nostrScheme' => 'Nostr Scheme',
			'containerCustomization' => 'Container customization',
			'backgroundColor' => 'Background color',
			'borderColor' => 'Border color',
			'value' => 'value',
			'pickYourComponent' => 'Pick your component',
			'selectComponent' => 'Select the component at convience and edit it.',
			'text' => 'text',
			'image' => 'image',
			'button' => 'button',
			'summaryOptional' => 'Summary (Optional)',
			'smartWidgetsDrafts' => 'Smart widgets drafts',
			'noSmartWidget' => 'No smart widgets drafts can be found',
			'noSmartWidgetCanBeFound' => 'No smart widgets can be found',
			'smartWidgetConvention' => 'This smart widget does not follow the agreed on convention.',
			'monolayoutRequired' => 'Monolayout is required',
			'zapPoll' => 'Zap poll',
			'layout' => 'layout',
			'container' => 'container',
			'edit' => 'edit',
			'moveUp' => 'Move up',
			'moveDown' => 'Move down',
			'delete' => 'delete',
			'editToAddZapPoll' => 'Edit to add zap poll',
			'options' => 'options',
			'smartWidgetBuilder' => 'Smart widget builder',
			'startBuildingSmartWidget' => 'Start building and customize your smart widget to use on the Nostr network',
			'blankWidget' => 'Blank widget',
			'myDrafts' => 'My drafts',
			'templates' => 'templates',
			'communityPolls' => 'Community polls',
			'myPolls' => 'My polls',
			'noPollsCanBeFound' => 'No polls can be found',
			'totalNumber' => ({required Object number}) => 'Total: ${number}',
			'smartWidgetsTemplates' => 'Smart widgets templates',
			'noTemplatesCanBeFound' => 'No templates can be found in this category.',
			'useTemplate' => 'Use template',
			'pickYourVideo' => 'Pick your video',
			'canUploadPastLink' => 'You can upload, paste a link or choose a kind 1063 nevent to your video.',
			'gallery' => 'Gallery',
			'link' => 'Link',
			'fileSharing' => 'File sharing',
			'setUpYourLink' => 'Set up your link',
			'setUpYourNevent' => 'Set up your nevent',
			'pasteYourLink' => 'Paste your link and submit it',
			'pasteKind1063' => 'Paste your kind 1063 nevent and submit it',
			'addUrlNevent' => 'Add a proper url/nevent',
			'nevent' => 'nevent',
			'addProperUrlNevent' => 'Add a proper url/nevent',
			'horizontalVideo' => 'Horizontal video',
			'preview' => 'Preview',
			'writeSummary' => 'Write a summary',
			'uploadImage' => 'Upload image',
			'addToCuration' => 'Add to curation',
			'submitCuration' => 'Submit curation',
			'selectValidUrlImage' => 'Select a valid url image.',
			'noCurationsFound' => 'No curations have been found. Try to create one in order to be able to add content to it.',
			'availableArticles' => ({required Object number}) => '${number} available article(s)',
			'availableVideos' => ({required Object number}) => '${number} available video(s)',
			'articlesNum' => ({required Object number}) => '${number} article(s)',
			'videosNum' => ({required Object number}) => '${number} video(s)',
			'articlesAvailableCuration' => 'Articles available on this curation',
			'videosAvailableCuration' => 'Videos available on this curation',
			'articleAddedCuration' => 'Article has been added to your curation.',
			'videoAddedCuration' => 'Video has been added to your curation.',
			'validTitleCuration' => 'Make sure to add a valid title for this curation',
			'validDescriptionCuration' => 'Make sure to add a valid description for this curation',
			'validImageCuration' => 'Make sure to add a valid image for this curation',
			'addCuration' => 'Add curation',
			'postedBy' => 'Posted by',
			'follow' => 'follow',
			'unfollow' => 'unfollow',
			'postedFrom' => 'posted from',
			'noTitle' => 'No title',
			'itemsNumber' => ({required Object number}) => '${number} item(s)',
			'noArticlesInCuration' => 'No articles on this curation have been found',
			'noVideosInCuration' => 'No videos on this curation have been found',
			'add' => 'add',
			'noBookmarksListFound' => 'No booksmarks list were found, try to add one!',
			'deleteBookmarkList' => 'Delete bookmark list',
			'confirmDeleteBookmarkList' => 'You\'re about to delete this bookmarks list, do you wish to proceed?',
			'bookmarks' => 'Bookmarks',
			'bookmarksListCount' => ({required Object number}) => '${number} bookmarks lists',
			'noDescription' => 'No description',
			'editedOn' => ({required Object date}) => 'Edited on: ${date}',
			'publishedOn' => ({required Object date}) => 'Published on: ${date}',
			'publishedOnText' => 'Published on',
			'lastUpdatedOn' => ({required Object date}) => 'Last updated on: ${date}',
			'joinedOn' => ({required Object date}) => 'Joined on: ${date}',
			'list' => 'list',
			'noElementsInBookmarks' => 'No elements can be found in bookmarks list',
			'draft' => 'draft',
			'note' => 'note',
			'notes' => 'notes',
			'smartWidget' => 'Smart Widget',
			'widgets' => 'widgets',
			'postNote' => 'Post note',
			'postArticle' => 'Post article',
			'postCuration' => 'Post curation',
			'postVideo' => 'Post video',
			'postSmartWidget' => 'Post smart widget',
			'ongoing' => 'ongoing',
			'componentsSMCount' => ({required Object number}) => '${number} components in this widget',
			'share' => 'share',
			'copyNoteId' => 'Copy note ID',
			'noteIdCopied' => 'Note id was copied! 👏',
			'confirmDeleteDraft' => 'You\'re about to delete this draft, do you wish to proceed?',
			'reposted' => 'reposted',
			'postInNote' => 'Post in note',
			'clone' => 'clone',
			'checkValidity' => 'Check validity',
			'copyNaddr' => 'copy naddr',
			'deleteContent' => ({required Object type}) => 'Delete ${type}',
			'confirmDeleteContent' => ({required Object type}) => 'You\'re about to delete this ${type}, do you wish to proceed?',
			'home' => 'Home',
			'followings' => 'Followings',
			'followers' => 'Followers',
			'replies' => 'replies',
			'zapReceived' => 'Zaps received',
			'totalAmount' => 'Total amount',
			'zapSent' => 'Zaps sent',
			'latest' => 'latest',
			'saved' => 'saved',
			'seeAll' => 'See all',
			'popularNotes' => 'Popular notes',
			'getStartedNow' => 'Get started now',
			'expandWorld' => 'Expand the world by adding what fascinates you. Select your interests and let the journey begins',
			'addInterests' => 'Add interests',
			'manageInterests' => 'Manage interests',
			'interests' => 'interests',
			'yakihonneImprovements' => 'YakiHonne\'s improvements',
			'yakihonneNote' => 'YakiHonne\'s note',
			'privacyNote' => 'Our app guarantees the utmost privacy by securely storing sensitive data locally on users\' devices, employing stringent encryption. Rest assured, we uphold a strict no-sharing policy, ensuring that sensitive information remains confidential and never leaves the user\'s device.',
			'pickYourMedia' => 'Pick your media',
			'uploadSendMedia' => 'You can upload and send media right after your selection or taking them.',
			'noMessagesToDisplay' => 'No messages to be displayed.',
			'enableSecureDmsMessage' => 'For more security & privacy, consider enabling Secure DMs.',
			'replyingTo' => ({required Object name}) => 'Replying to: ${name}',
			'writeYourMessage' => 'Write a message',
			'zap' => 'zap',
			'disableSecureDms' => 'Disable Secure DMs',
			'enableSecureDms' => 'Enable Secure DMs',
			'notUsingSecureDms' => 'You are no longer using Secure Dms',
			'usingSecureDms' => 'You are now using Secure Dms',
			'mute' => 'mute',
			'unmute' => 'unmute',
			'muteUser' => 'Mute user',
			'unmuteUser' => 'Unmute user',
			'muteUserDesc' => ({required Object name}) => 'Your are about to mute ${name}, do you wish to proceed?',
			'unmuteUserDesc' => ({required Object name}) => 'Your are about to unmute ${name}, do you wish to proceed?',
			'messageCopied' => 'Message successfully copied!',
			'messageNotDecrypted' => 'Message has not been decrypted yet!',
			'reply' => 'reply',
			'newMessage' => 'New message',
			'searchNameNpub' => 'Search by name, npub, nprofile',
			'searchByUserName' => 'Search by username',
			'known' => 'Known',
			'unknown' => 'Unknown',
			'noMessageCanBeFound' => 'No messages can be found',
			'you' => 'You: ',
			'decrMessage' => 'Decrypting message',
			'gifs' => 'gifs',
			'stickers' => 'stickers',
			'customizeYourFeed' => 'Customize your feed',
			'feedOptions' => 'Feed options',
			'recent' => 'recent',
			'recentWithReplies' => 'Recent with replies',
			'explore' => 'explore',
			'following' => 'following',
			'trending' => 'trending',
			'highlights' => 'highlights',
			'paid' => 'paid',
			'others' => 'others',
			'suggestionsBox' => 'Suggestions box',
			'showSuggestions' => 'Show suggestions',
			'showSuggestedPeople' => 'Show suggested people to follow',
			'showArticlesNotesSuggestions' => 'Show articles/notes suggestions',
			'showSuggestedInterests' => 'Show suggested interests',
			'readTime' => ({required Object time}) => '${time}m read',
			'watchNow' => 'watch now',
			'bookmark' => 'bookmark',
			'suggestions' => 'Suggestions',
			'hideSuggestions' => 'Hide suggestions',
			'enjoyExpOwnData' => 'Enjoy the experience of owning\nyour own data!',
			'signIn' => 'Sign in',
			'createAccount' => 'Create account',
			'byContinuing' => 'By continuing you agree with our\n',
			'eula' => 'End User Licence Agreement (EULA)',
			'continueAsGuest' => 'Continue as a guest',
			'heyWelcomeBack' => 'Hey,\nWelcome\nBack',
			'npubNsecHex' => 'npub, nsec or hex',
			'useAmber' => 'Use Amber',
			'setValidKey' => 'Set a valid key',
			'pasteYourKey' => 'Paste your key',
			'taylorExperienceInterests' => 'Tailor your experience by selecting your top interests',
			'peopleCountPlus' => ({required Object number}) => '+${number} people',
			'followAll' => 'Follow all',
			'unfollowAll' => 'Unfollow all',
			'details' => 'details',
			'shareGlimps' => 'Share a glimpse of you, in words that feel true.',
			'addCover' => 'Add cover',
			'editCover' => 'Edit cover',
			'yourName' => 'Your name',
			'setProperName' => 'Set a proper name',
			'aboutYou' => 'About you',
			'secKeyDesc' => 'You can find your account secret key in your settings. This key is essential to secure access to your account. Please keep it safe and private.',
			'secKeyWalletDesc' => 'You can find your account secret key and wallet connection secret in your settings. These keys are essential to secure access to your account and wallet. Please keep them safe and private.',
			'initializingAccount' => 'Initializing account...',
			'letsGetStarted' => 'Let\'s get started!',
			'dontHaveWallet' => 'Don\'t have a wallet?',
			'createWalletSendRecSats' => 'Create a wallet to send and receive sats',
			'createWallet' => 'Create wallet',
			'youreAllSet' => 'You\'re all set',
			'dashboard' => 'dashboard',
			'verifyNotes' => 'Verify notes',
			'settings' => 'settings',
			'manageAccounts' => 'Manage accounts',
			'login' => 'Login',
			'switchAccounts' => 'Switch accounts',
			'addAccount' => 'Add account',
			'logoutAllAccounts' => 'Logout all accounts',
			'search' => 'search',
			'smartWidgets' => 'Smart widgets',
			'notifications' => 'notifications',
			'inbox' => 'inbox',
			'discover' => 'discover',
			'wallet' => 'wallet',
			'publicKey' => 'Public key',
			'profileLink' => 'Profile link',
			'profileCopied' => 'Profile link was copied! 👏',
			'publicKeyCopied' => 'Public key was copied! 👏',
			'lnCopied' => 'lightning address was copied! 👏',
			'scanQrCode' => 'Scan QR code',
			'viewQrCode' => 'View QR code',
			'copyNpub' => 'Copy pubkey',
			'visitProfile' => 'Visit profile',
			'followMeOnNostr' => 'Follow me on Nostr',
			'close' => 'close',
			'loadingPreviousPosts' => 'Loading previous post(s)...',
			'noRepliesDesc' => 'No replies for this note can be found',
			'thread' => 'thread',
			'all' => 'all',
			'mentions' => 'mentions',
			'zaps' => 'zaps',
			'noNotificationCanBeFound' => 'No notifications can be found',
			'consumablePointsPerks1' => '1- Submit your content for attestation',
			'consumablePointsPerks2' => '2- Redeem points to publish paid notes',
			'consumablePointsPerks3' => '3- Redeem points for SATs (Random thresholds are selected and you will be notified whenever redemption is available)',
			'yakihonneConsPoints' => 'YakiHonne\'s Consumable points',
			'soonUsers' => 'Soon users will be able to use the consumable points in the following set of activities:',
			'startEarningPoints' => 'Start earning and make the most of your Yaki Points! 🎉',
			'gotIt' => 'Got it!',
			'engagementChart' => 'Engagement chart',
			'lastGained' => ({required Object date}) => 'Last gained: ${date}',
			'attemptsRemained' => 'Attempts remained ',
			'congratulations' => 'Congratulations',
			'congratsDesc' => ({required Object number}) => 'You have been rewarded ${number} xp for the following actions, be active and earn rewards!',
			'yakihonneChest' => 'YakiHonne\'s Chest!',
			'noImGood' => 'No, I\'m good',
			'points' => 'Points',
			'unlocked' => 'Unlocked',
			'locked' => 'Locked',
			'whatsThis' => 'What\'s this?',
			'levelNumber' => ({required Object number}) => 'Level ${number}',
			'pointsSystem' => 'Points system',
			'oneTimeRewards' => 'One time rewards',
			'repeatedRewards' => 'Repeated rewards',
			'consumablePoints' => 'Consumable points',
			'pointsRemaining' => ({required Object number}) => '${number} remaining',
			'gain' => 'Gain',
			'forName' => ({required Object name}) => 'for ${name}',
			'min' => 'min',
			'levelsRequiredNum' => ({required Object number}) => '${number} levels required',
			'seeMore' => 'See more',
			'deleteCoverPic' => 'Delete cover picture!',
			'deleteCoverPicDesc' => 'You\'re about to delete your cover picture, do you wish to proceed?',
			'editProfile' => 'Edit profile',
			'uploadingImage' => 'Uploading image...',
			'updateProfile' => 'Update Profile',
			'userName' => 'User name',
			'displayName' => 'Display name',
			'yourDisplayName' => 'Your display name',
			'writeSomethingAboutYou' => 'Write something about you!',
			'website' => 'Website',
			'yourWebsite' => 'Your website',
			'verifyNip05' => 'Verified Nostr Address (NIP 05)',
			'enterNip05' => 'Enter your NIP-05 address',
			'enterLn' => 'Enter your address LUD-06 or LUD-16',
			'less' => 'Less',
			'more' => 'More',
			'pictureUrl' => 'Picture url',
			'coverUrl' => 'Cover url',
			'enterPictureUrl' => 'Enter your picture url',
			'enterCoverUrl' => 'Enter your cover url',
			'userNoArticles' => ({required Object name}) => '${name} has no articles',
			'userNoCurations' => ({required Object name}) => '${name} has no curations',
			'userNoNotes' => ({required Object name}) => '${name} has no notes',
			'userNoVideos' => ({required Object name}) => '${name} has no videos',
			'loadingFollowings' => 'Loading followings',
			'loadingFollowers' => 'loading followers',
			'followersNum' => ({required Object number}) => '${number} followers',
			'notFollowedByAnyoneYouFollow' => 'Not followed by anyone you follow.',
			'mutuals' => 'mutual(s)',
			'mutualsNum' => ({required Object number}) => '+ ${number} mutual(s)',
			'followsYou' => 'Follows you',
			'userNameCopied' => 'User name was successfully copied!',
			'profileRelays' => ({required Object number}) => 'Profile recommended relays - ${number}',
			'noUserRelays' => 'No relays for this user were found.',
			'userNoSmartWidgets' => ({required Object name}) => '${name} has no smart widgets',
			'un1' => 'Ratings of Not Helpful on notes that ended up with a status of Helpful',
			'un1Desc' => 'These ratings are counted twice because they often indicate support for notes that others deemed helpful.',
			'un2' => 'Notes with ongoing ratings',
			'un2Desc' => 'Ratings on notes that don\'t currently have a status of Helpful or Not Helpful',
			'unTextW1' => 'Notes that earned the status of Helpful',
			'unTextW1Desc' => 'These notes are now showing to everyone who sees the post, adding context and helping keep people informed.',
			'unTextR1' => 'Ratings that helped a note earn the status of Helpful',
			'unTextR1Desc' => 'These ratings identified Helpful notes that gets shown to everyone, adding context and helping keep people informed.',
			'unTextW2' => 'Notes that reached the status of Not Helpful',
			'unTextW2Desc' => 'These notes have been rated Not Helpful by enough contributors, including those who sometimes disagree in their past ratings.',
			'unTextR2' => 'Ratings that helped a note earn the status of Not Helpful',
			'unTextR2Desc' => 'These ratings improve Verified Notes by giving feedback to note authors, and allowing contributors to focus on the most promising notes',
			'unTextW3' => 'Notes that need more ratings',
			'unTextW3Desc' => 'Notes that don\'t yet have a status of Helpful or Not Helpful.',
			'unTextR3' => 'Ratings of Not Helpful on notes that ended up with a status of Helpful',
			'unTextR3Desc' => 'Don\'t worry, everyone gets some of these! These ratings are common and can lead to status changes if enough people agree that a \'Helpful\' note isn\'t sufficiently helpful.',
			'refresh' => 'refresh',
			'userImpact' => 'User\'s impact',
			'userRelays' => 'User\'s relays',
			'rewards' => 'rewards',
			'noRewards' => 'You have no rewards, interact with or write verified notes in order to obtain them.',
			'onDate' => ({required Object date}) => 'On ${date}',
			'youHaveRated' => 'You have rated',
			'theFollowingNote' => 'the following note:',
			'youHaveLeftNote' => 'You have left a note on this paid note:',
			'paidNoteLoading' => 'Paid note loading',
			'yourNoteSealed' => 'Your following note just got sealed:',
			'ratedNoteSealed' => 'You have rated the following note which got sealed:',
			'claimTime' => ({required Object time}) => 'Claim in ${time}',
			'claim' => 'Claim',
			'requestInProgress' => 'Request in progress',
			'granted' => 'Granted',
			'interested' => 'Interested',
			'notInterested' => 'Not interested',
			'noResKeyword' => 'No result for this keyword',
			'noResKeywordDesc' => 'No results have been found using this keyword, try to use another keywords in order to get a better results.',
			'startSearchPeople' => 'Start searching for people',
			'startSearchContent' => 'Start searching for content',
			'keys' => 'Keys',
			'myPublicKey' => 'My public key',
			'mySecretKey' => 'My secret key',
			'show' => 'show',
			'showSecret' => 'Show secret key!',
			'showSecretDesc' => 'Make sure to keep it safe as it gives a full access to your account.',
			'usingExternalSign' => 'Using an external signer',
			'usingExternalSignDesc' => 'You are using an external signer',
			'privKeyCopied' => 'Private key was copied! 👏',
			'muteList' => 'Mute list',
			'noMutedUserFound' => 'No muted users have been found.',
			'searchRelay' => 'Search relay',
			'deleteAccount' => 'Delete account',
			'clearAppCache' => 'Clear app cache',
			'clearAppCacheDesc' => 'You are about to clear the app cache, do you wish to proceed?',
			'clear' => 'clear',
			'fontSize' => 'Font Size',
			'appTheme' => 'App theme',
			'contentModeration' => 'Content moderation',
			'mediaUploader' => 'Media uploader',
			'secureDirectMessaging' => 'Secure direct messaging',
			'customization' => 'Customization',
			'hfCustomization' => 'Home feed customization',
			'newPostGesture' => 'New post long press gesture',
			'profilePreview' => 'Profile preview',
			'relaySettings' => ({required Object number}) => 'Relay settings ${number}',
			'yakihonne' => 'YakiHonne',
			'wallets' => 'wallets',
			'addWallet' => 'Add wallet',
			'externalWallet' => 'External wallet',
			'yakiChest' => 'Yaki chest',
			'connected' => 'Connected',
			'connect' => 'Connect',
			'owner' => 'Owner',
			'contact' => 'Contact',
			'software' => 'Software',
			'version' => 'Version',
			'supportedNips' => 'Supported Nips',
			'instantConntect' => 'Instant connect to relay',
			'invalidRelayUrl' => 'Invalid relay url',
			'relays' => 'Relays',
			'readOnly' => 'Read only',
			'writeOnly' => 'Write only',
			'readWrite' => 'Read/Write',
			'defaultKey' => 'Default',
			'viewProfile' => 'View profile',
			'appearance' => 'Appearance',
			'untitled' => 'Untitled',
			'smartWidgetChecker' => 'Smart widget checker',
			'naddr' => 'naddr',
			'noComponentsDisplayed' => 'No components can be displayed',
			'metadata' => 'metadata',
			'createdAt' => 'Created at',
			'identifier' => 'Identifier',
			'enterSMaddr' => 'Enter a smart widget naddr to check for its validity.',
			'notFindSMwithAddr' => 'Could not find smart widget with such address',
			'unableToOpenUrl' => 'Unable to open url',
			'voteToSeeStats' => 'You should vote to be able to see stats',
			'votesByZaps' => 'Votes by zaps',
			'votesByUsers' => 'Votes by users',
			'alreadyVoted' => 'You have already voted on this poll',
			'userCannotBeFound' => 'User cannot be found',
			'votesNumber' => ({required Object number}) => 'Votes: ${number}',
			'voteRequired' => 'Vote is required to display stats.',
			'showStats' => 'Show stats',
			'pollClosesAt' => ({required Object date}) => 'Closes at: ${date}',
			'pollClosedAt' => ({required Object date}) => 'Closed at: ${date}',
			'checkSmartWidget' => 'Check a smart widget',
			'emptyVerifiedNote' => 'Empty verified note content!',
			'post' => 'Post',
			'seeAnything' => 'See anything you want to improve?',
			'writeNote' => 'Write a note',
			'whatThinkThis' => 'What do you think about this ?',
			'sourceRecommended' => 'Source (recommended)',
			'findPaidNoteCorrect' => 'You find this paid note correct.',
			'findPaidNoteMisleading' => 'You find this paid note misleading.',
			'selectOneReason' => 'Select at least one reason',
			'rateHelpful' => 'Rate helpful',
			'rateNotHelpful' => 'Rate not helpful',
			_ => null,
		};
	}

	dynamic _flatMapFunction$1(String path) {
		return switch (path) {
			'ratedHelpful' => 'Rated helpful',
			'ratedNotHelpful' => 'Rated not helpful',
			'youRatedHelpful' => 'you rated this as helpful',
			'youRatedNotHelpful' => 'you rated this as not helpful',
			'findThisHelpful' => 'Do you find this helpful?',
			'findThisNotHelpful' => 'Do you find this not helpful?',
			'setYourRating' => 'Set your rating',
			'whatThinkOfThat' => 'What do you think of that?',
			'changeRatingNote' => 'Note: changing your rating will only be valid for 5 minutes, after that you will no longer have the option to undo or change it.',
			'paidNote' => 'Paid note',
			'undo' => 'Undo',
			'undoRating' => 'Undo rating',
			'undoRatingDesc' => 'You are about to undo your rating, do you wish to proceed?',
			'seeAllAttempts' => 'See all attempts',
			'addNote' => 'Add note',
			'alreadyContributed' => 'You have already contributed',
			'notesFromCommunity' => 'Notes from the community',
			'noCommunityNotes' => 'It\'s quiet here! No community notes yet.',
			'notHelpful' => 'Not helpful',
			'sealed' => 'Sealed',
			'notSealed' => 'Not sealed',
			'notSealedYet' => 'Not sealed yet',
			'needsMoreRating' => 'Needs more rating',
			'source' => 'Source',
			'thisNoteAwaitRating' => 'this note is awaiting community rating.',
			'yourNoteAwaitRating' => 'this note is awaiting community rating.',
			'topReasonsSelected' => 'Top reasons selected by raters:',
			'noReasonsSpecified' => 'No reasons are specified!',
			'postedOn' => ({required Object date}) => 'Posted on ${date}',
			'explanation' => 'Explanation',
			'readAboutVerifyingNotes' => 'Read about verifying notes',
			'readAboutVerifyingNotesDesc' => 'We\'ve made an article for you to help you understand our purpose',
			'readArticle' => 'Read article',
			'whyVerifyingNotes' => 'Why the verifying notes?',
			'contributeUnderstanding' => 'Contribute to build understanding',
			'actGoodFaith' => 'Act in good faith',
			'beHelpful' => 'Be helpful, even to those who disagree',
			'readMore' => 'Read more',
			'newKey' => 'New',
			'needsYourHelp' => 'Needs your helpful',
			'communityWallet' => 'Community wallet',
			'noPaidNotesCanBeFound' => 'No paid notes can be found.',
			'updatesNews' => 'Updates news',
			'updates' => 'Updates',
			'toBeAbleSendSats' => 'To be able to send zaps, please make sure to connect your bitcoin lightning wallet.',
			'receiveSats' => 'Receive sats',
			'messageOptional' => 'Message (optional)',
			'amountInSats' => 'Amount in sats',
			'invoiceCopied' => 'Invoice code copied!',
			'copyInvoice' => 'Copy invoice',
			'ensureLnSet' => 'Ensure that your lightning address is well set',
			'errorGeneratingInvoice' => 'Error occured while generating invoice',
			'generateInvoice' => 'Generate invoice',
			'qrCode' => 'QR code',
			'scanPay' => 'Scan & pay',
			'slideToPay' => 'Slide to pay',
			'invalidInvoice' => 'Invalid invoice',
			'invalidInvoiceDesc' => 'It seems that the scanned invoice is invalid, re-scan and try again.',
			'scanAgain' => 'Scan again',
			'sendSats' => 'Send sats',
			'send' => 'Send',
			'recentTransactions' => 'Recent transactions',
			'noTransactionCanBeFound' => 'No transactions can be found',
			'selectWalletTransactions' => 'Select a wallet to obtain latest transactions.',
			'noUserCanBeFound' => 'No users can be found.',
			'balance' => 'Balance',
			'noLnInNwc' => 'We could not retrieve your address from your NWC secret, kindly check your lightning address service provider to copy your address or to update your profile accordinaly.',
			'copyLn' => 'Copy lightning address',
			'receive' => 'Receive',
			'clickBelowToConnect' => 'Click below to connect',
			'connectWithNwc' => 'Connect with NWC',
			'pasteNwcAddress' => 'Paste NWC address',
			'createYakiWallet' => 'Create YakiHonne\'s wallet',
			'yakiNwc' => 'YakiHonne\'s NWC',
			'yakiNwcDesc' => 'Create wallet using YakiHonne\'s channel',
			'orUseYourWallet' => 'Or use your wallet',
			'nostrWalletConnect' => 'Nostr wallet connect',
			'nostrWalletConnectDesc' => 'Native nostr wallet connection',
			'alby' => 'Alby',
			'albyConnect' => 'Alby connect',
			'walletDataNote' => 'Note: All the data related to your wallet will be safely and securely stored locally and are never shared outside the confines of the application.',
			'availableWallets' => 'Available wallets',
			'noWalletLinkedToYouProfile' => 'You have no wallet linked to your profile.',
			'noWalletConnectedToYourProfile' => 'None of the connected wallets are linked to your profile.',
			'click' => 'Click',
			'onSelectedWalletLinkIt' => 'on your selected wallet & link it.',
			'noWalletCanBeFound' => 'No wallet can be found',
			'currentlyLinkedMessage' => 'Currently linked with your profile for zaps receiving',
			'linked' => 'Linked',
			'linkWallet' => 'Link wallet',
			'linkWalletDesc' => 'You are about to override your previous wallet and link a new one to your profile, do you wish to proceed?',
			'copyNwc' => 'Copy NWC',
			'nwcCopied' => 'NWC has been successfuly copied!',
			'deleteWallet' => 'Delete wallet',
			'deleteWalletDesc' => 'You are about to delete this wallet, do you wish to proceed?',
			'userSentSat' => ({required Object name, required Object number}) => '${name} sent you ${number} Sats',
			'userReceivedSat' => ({required Object name, required Object number}) => '${name} received from you ${number} Sats',
			'ownSentSat' => ({required Object number}) => 'You sent ${number} Sats',
			'ownReceivedSat' => ({required Object number}) => 'You received ${number} Sats',
			'comment' => 'Comment',
			'supportYakihonne' => 'Support YakiHonne',
			'fuelYakihonne' => 'Fuel YakiHonne\'s growth! Your support drives new features and a better experience for everyone.',
			'supportUs' => '❤︎ Support us',
			'peopleToFollow' => 'People to follow',
			'donations' => 'Donations',
			'inTag' => ({required Object name}) => 'In ${name}',
			'shareProfile' => 'Share profile',
			'shareProfileDesc' => 'Share your profile to reach more people, connect with others, and grow your network',
			'moreDots' => 'more...',
			'comments' => 'Comments',
			'noCommentsCanBeFound' => 'No comments can be found',
			'beFirstCommentThisVideo' => 'Be the first to comment on this video !',
			'errorLoadingVideo' => 'Error while loading the video',
			'seeAlso' => 'See also',
			'viewsNumber' => ({required Object number}) => '${number} view',
			'upvotes' => 'Upvotes',
			'downvotes' => 'Downvotes',
			'views' => 'Views',
			'createdAtEditedAt' => ({required Object date1, required Object date2}) => 'created at ${date1}, edited on ${date2}',
			'loading' => 'Loading',
			'releaseToLoad' => 'Release to load more',
			'finished' => 'finished!',
			'noMoreData' => 'No more data',
			'refreshed' => 'Refreshed',
			'refreshing' => 'Refreshing',
			'pullToRefresh' => 'Pull to refresh',
			'suggestedInterests' => 'Suggested interests',
			'reveal' => 'Reveal',
			'wantToShareRevenues' => 'I want to share this revenues',
			'splitRevenuesWithUsers' => 'Split revenues with users',
			'addUser' => 'Add user',
			'selectAdate' => 'Select a date',
			'clearDate' => 'Clear date',
			'nothingToShowHere' => 'Oops! Nothing to show here!',
			'confirmPayment' => 'Confirm payment',
			'payWithNwc' => 'Pay with NWC',
			'important' => 'Important',
			'adjustVolume' => 'Adjust volume',
			'adjustSpeed' => 'Adjust speed',
			'updateInterests' => 'Update interests',
			'usingViewMode' => 'You\'re using view mode',
			'usingViewModeDesc' => 'Sign in with your private key and join the community.',
			'noInternetAccess' => 'No internetAccess',
			'checkModelRouter' => 'Check your modem or router',
			'reconnectWifi' => 'Reconnect to a wifi',
			'somethingWentWrong' => 'Something went wrong !',
			'somethingWentWrongDesc' => 'It looks like something happened while loading the data, try again!',
			'tryAgain' => 'Try again',
			'postNotFound' => 'Post could not be found',
			'user' => 'user',
			'view' => 'view',
			'itsLive' => 'It\'s live!',
			'spreadWordSharingContent' => 'Spread the word by sharing your content everywhere.',
			'successfulRelays' => 'Successful relays',
			'noRelaysCanBeFound' => 'No relays can be found',
			'dismiss' => 'dismiss',
			'deleteAccountMessage' => 'You are attempting to login to a deleted account.',
			'exit' => 'Exit',
			'shareContent' => 'Share content',
			'profile' => 'Profile',
			'by' => 'by',
			'shareLink' => 'Share link',
			'shareImage' => 'Share image',
			'shareNoteId' => 'Share note id',
			'shareNprofile' => 'Share nprofile',
			'shareNaddr' => 'Share naddr',
			'bio' => ({required Object content}) => 'Bio: ${content}',
			'earnSats' => 'Earn SATs',
			'earnSatsDesc' => 'Help us provide more decentralized insights to review this paid note.',
			'verifyingNote' => 'Verifying note',
			'pickYourImage' => 'Pick your image',
			'uploadPasteUrl' => 'You can upload or paste a url for your preffered image',
			'back' => 'back',
			'camera' => 'Camera',
			'communityWidgets' => 'Community widgets',
			'myWidgets' => 'My widgets',
			'pendingUnfollowing' => 'Unfollowing...',
			'pendingFollowing' => 'Following...',
			'zappers' => 'Zappers',
			'noZappersCanBeFound' => 'No zappers can be found.',
			'payPublish' => 'Pay & Publish',
			'payPublishNote' => 'Note: Ensure that all the content that you provided is final since the publishing is deemed irreversible & the spent SATS are non refundable.',
			'userSubmittedPaidNote' => ({required Object name}) => '${name} has submitted a paid note',
			'getInvoice' => 'Get invoice',
			'pay' => 'Pay',
			'compose' => 'Compose',
			'writeSomething' => 'Write something...',
			'highlightedNote' => 'A highlighted note for more exposure.',
			'typeValidZapQuestion' => 'Type a valid poll question!',
			'pollOptions' => 'Poll options',
			'minimumSatoshis' => 'Minimum satoshis',
			'minSats' => 'Min sats',
			'maxSats' => 'Max sats',
			'maximumSatoshis' => 'Maximum satoshis',
			'pollCloseDate' => 'Poll close date',
			'optionsNumber' => ({required Object number}) => 'Options: ${number}',
			'zapSplits' => 'Zap splits',
			'minimumOfOneRequired' => 'A minimum amount of 1 is required',
			'valueBetweenMinMax' => 'The value should be between the min and max sats amount',
			'writeCommentOptional' => 'Write a comment (optional)',
			'splitZapsWith' => 'Split zaps with',
			'useCannotBeZapped' => 'This user cannot be zapped',
			'waitingGenerationOfInvoice' => 'Waiting for the generation of invoices.',
			'userInvoiceGenerated' => ({required Object name}) => 'An invoice for ${name} has been generated',
			'userInvoiceNotGenerated' => 'Could not create an invoice for this user.',
			'payAmount' => ({required Object number}) => 'Pay ${number} sats',
			'generateInvoices' => 'Generate invoices',
			'userZappedSuccesfuly' => 'User was zapped successfuly',
			'useValidTitle' => 'A valid title needs to be used',
			'errorAddingBookmark' => 'Error occured when adding the bookmark',
			'bookmarkAdded' => 'Bookmark list has been added',
			'voteNotSubmitted' => 'Vote could not be submitted',
			'zapSplitsMessage' => 'For zap splits, there should be at least one person',
			'errorUpdatingCuration' => 'An error occured while updating the curation',
			'errorAddingCuration' => 'An error occured while adding the curation',
			'errorDeletingContent' => 'Error occured while deleting content',
			'errorSigningEvent' => 'Error occured while signing the event',
			'errorSendingEvent' => 'Error occured while sending the event',
			'errorSendingMessage' => 'error occured while sending the message',
			'userHasBeenMuted' => 'User has been muted',
			'userHasBeenUnmuted' => 'User has been unmuted',
			'messageCouldNotBeDecrypted' => 'message could not be decrypted',
			'interestsUpdateMessage' => 'Interest list has been updated successfuly!',
			'errorGeneratingEvent' => 'Error occured while generating event',
			'oneFeedOptionAvailable' => 'There should be at least one feed option available.',
			'walletCreated' => 'Wallet has been created successfuly',
			'walletLinked' => 'Wallet has been linked successfuly',
			'errorCreatingWallet' => 'Error occured while creating wallet',
			'walletNotLinked' => 'Wallet cannot be linked. Wrong lighting address',
			'invalidPairingSecret' => 'Invalid pairing secret',
			'errorSettingToken' => 'Error occured while setting up the token',
			'nwcInitialized' => 'Nostr wallet connect has been initialized',
			'noWalletLinkedMessage' => 'You have no wallet linked to your profile, do you wish to link this wallet?',
			'errorUsingWallet' => 'Error occured while using wallet!',
			'submitValidData' => 'Make sure you submit a valid data',
			'submitValidInvoice' => 'Make sure you submit a valid invoice',
			'paymentSucceeded' => 'Payment succeeded',
			'paymentFailed' => 'Payment failed',
			'notEnoughBalance' => 'Not enough balance to make this payment.',
			'permissionInvoiceNotGranted' => 'Permission to pay invoices is not granted.',
			'allUsersZapped' => 'All the users have been zapped!',
			'partialUsersZapped' => 'Partial users are zapped!',
			'noUserZapped' => 'No user has been zapped!',
			'errorZappingUsers' => 'Error occured while zapping users',
			'selectDefaultWallet' => 'Select a default wallet in the settings.',
			'noInvoiceAvailable' => 'No invoices are available',
			'invoicePaid' => 'Invoice has been paid successfuly',
			'errorPayingInvoice' => 'Error occured while paying using invoice',
			'errorUsingExternalWallet' => 'Error while using external wallet.',
			'paymentSurpassMax' => 'Payment Surpasses the maximum amount allowed.',
			'errorSendingSats' => 'Error occured while sending sats',
			'setSatsMoreThanZero' => 'Set a sats amount greater than 0',
			'processCompleted' => 'Process has been completed',
			'relayingStuff' => 'Relaying stuff...',
			'amberNotInstalled' => 'Amber app is not installed',
			'alreadyLoggedIn' => 'You are already logged in!',
			'loggedIn' => 'You are logged in!',
			'attemptConnectAmber' => 'Attempt to connect with Amber has been rejected.',
			'errorUploadingImage' => 'Error ocurred while uploading image',
			'invalidPrivateKey' => 'Invalid private key!',
			'invalidHexKey' => 'Invalid hex key!',
			'fetchingArticle' => 'Fetching article',
			'articleNotFound' => 'Article could not be found',
			'fetchingCuration' => 'Fetching curation',
			'curationNotFound' => 'Curation could not be found',
			'fetchingSmartWidget' => 'Fetching smart widget',
			'smartWidgetNotFound' => 'Smart widget could not be found',
			'fetchingVideo' => 'Fetching video',
			'videoNotFound' => 'Video could not be found',
			'fetchingNote' => 'Fetching note',
			'noteNotFound' => 'Note could not be found',
			'eventNotFound' => 'Event could not be found',
			'verifiedNoteNotFound' => 'Verified note could not be found',
			'eventNotRecognized' => 'Event could not be recognized',
			'fetchingEventUserRelays' => 'Fetching event from user\'s relays',
			'fetchingProfile' => 'Fetching profile',
			'fetchingEvent' => 'Fetching event',
			'loggedToYakiChest' => 'You are logged in to Yakihonne\'s chest',
			'errorLoggingYakiChest' => 'Error occured while logging in to Yakihonne\'s chest',
			'relayInUse' => 'Relay already in use',
			'errorConnectingRelay' => 'Error occured while connecting to relay',
			'submitValidLud' => 'Make sure to get a valid lud16/lud06.',
			'errorUpdatingData' => 'Error occured while updating data',
			'updatedSuccesfuly' => 'Updated successfuly',
			'relaysListUpdated' => 'Relays list has been updated',
			'couldNotUpdateRelaysList' => 'Could not update relays list',
			'errorUpdatingRelaysList' => 'Error occured while updating relays list',
			'errorClaimingReward' => 'Error occured while claimaing a reward',
			'errorDecodingData' => 'Error occured while decoding data',
			'loggingIn' => 'Logging in...',
			'loggingOut' => 'Logging out...',
			'disconnecting' => 'Disconnecting...',
			'ratingSubmittedCheckReward' => 'Your rating has been submitted, check your rewards page to claim your rating reward',
			'errorSubmittingRating' => 'Error occured while submitting your rating',
			'verifiedNoteAdded' => 'Your verified note has been added, check your rewards page to claim your writing reward',
			'errorAddingVerifiedNote' => 'Error occured while adding your verified note',
			'ratingDeleted' => 'Your rating has been deleted',
			'errorDeletingRating' => 'Error occured while deleting your rating',
			'autoSavedArticleDeleted' => 'Auto-saved article has been deleted',
			'articlePublished' => 'Your article has been published!',
			'errorAddingArticle' => 'An error occured while adding the article',
			'writeValidNote' => 'Write down a valid note!',
			'setOutboxRelays' => 'Make sure to set up your outbox relays',
			'notePublished' => 'Note has been published!',
			'paidNotePublished' => 'Paid note has been published!',
			'invoiceNotPayed' => 'It seemse that you didn\'t pay the invoice, recheck again',
			'autoSavedSMdeleted' => 'Auto-saved smart widget has been deleted',
			'errorUploadingMedia' => 'Error occured while uploading the media',
			'smartWidgetPublishedSuccessfuly' => 'Smart widget has been published successfuly',
			'errorAddingWidget' => 'An error occured while adding the smart widget',
			'setAllRequiredContent' => 'Make sure to set all the required content.',
			'noEventIdCanBeFound' => 'No event with this id can be found!',
			'notValidVideoEvent' => 'This event is not a valid video event!',
			'emptyVideoUrl' => 'This nevent has an empty url',
			'submitValidVideoEvent' => 'Please submit a valid video event',
			'errorUploadingVideo' => 'Error occured while uploading the video',
			'errorAddingVideo' => 'An error occured while adding the video',
			'submitMinMaxSats' => 'Make sure to submit valid minimum & maximum satoshis',
			'submitValidCloseDate' => 'Make sure to submit valid close date.',
			'submitValidOptions' => 'Make sure to submit valid options.',
			'pollZapPublished' => 'Poll zap has been published!',
			'relaysNotReached' => 'Relays could not be reached',
			'loginYakiChestPoints' => 'Login to Yakihonne\'s chest, accumulate points by being active on the platform and win precious awards!',
			'inaccessibleLink' => 'Inaccessible link',
			'mediaExceedsMaxSize' => 'Media exceeds the maximum size which is 21 mb',
			'fetchingUserInboxRelays' => 'Fetching user inbox relays',
			'userZappedYou' => ({required Object name, required Object number}) => '${name} zapped you ${number} sats',
			'userReactedYou' => ({required Object name, required Object reaction}) => '${name} reacted ${reaction} to you',
			'userRepostedYou' => ({required Object name}) => '${name} reposted your content',
			'userMentionedYouInComment' => ({required Object name}) => '${name} mentioned you in a comment',
			'userMentionedYouInNote' => ({required Object name}) => '${name} mentioned you in a note',
			'userMentionedYouInPaidNote' => ({required Object name}) => '${name} mentioned you in a paid note',
			'userMentionedYouInArticle' => ({required Object name}) => '${name} mentioned you in an article',
			'userMentionedYouInVideo' => ({required Object name}) => '${name} mentioned you in a video',
			'userMentionedYouInCuration' => ({required Object name}) => '${name} mentioned you in a curation',
			'userMentionedYouInSmartWidget' => ({required Object name}) => '${name} mentioned you in a smart widget',
			'userMentionedYouInPoll' => ({required Object name}) => '${name} mentioned you in a poll',
			'userPublishedPaidNote' => ({required Object name}) => '${name} published a paid note',
			'userPublishedArticle' => ({required Object name}) => '${name} published an article',
			'userPublishedVideo' => ({required Object name}) => '${name} published a video',
			'userPublishedCuration' => ({required Object name}) => '${name} published a curation',
			'userPublishedSmartWidget' => ({required Object name}) => '${name} published a smart widget',
			'userPublishedPoll' => ({required Object name}) => '${name} published a poll',
			'userZappedYourArticle' => ({required Object name, required Object number}) => '${name} zapped your article ${number} sats',
			'userZappedYourCuration' => ({required Object name, required Object number}) => '${name} zapped your curation ${number} sats',
			'userZappedYourVideo' => ({required Object name, required Object number}) => '${name} zapped your video ${number} sats',
			'userZappedYourSmartWidget' => ({required Object name, required Object number}) => '${name} zapped your smart widget ${number} sats',
			'userZappedYourPoll' => ({required Object name, required Object number}) => '${name} zapped your poll ${number} sats',
			'userZappedYourNote' => ({required Object name, required Object number}) => '${name} zapped your note ${number} sats',
			'userZappedYourPaidNote' => ({required Object name, required Object number}) => '${name} zapped your paid note ${number} sats',
			'userReactedYourArticle' => ({required Object name, required Object reaction}) => '${name} reacted ${reaction} to your article',
			'userReactedYourCuration' => ({required Object name, required Object reaction}) => '${name} reacted ${reaction} to your curation',
			'userReactedYourVideo' => ({required Object name, required Object reaction}) => '${name} reacted ${reaction} to your video',
			'userReactedYourSmartWidget' => ({required Object name, required Object reaction}) => '${name} reacted ${reaction} to your smart widget',
			'userReactedYourPoll' => ({required Object name, required Object reaction}) => '${name} reacted ${reaction} to your poll',
			'userReactedYourNote' => ({required Object name, required Object reaction}) => '${name} reacted ${reaction} to your note',
			'userReactedYourPaidNote' => ({required Object name, required Object reaction}) => '${name} reacted ${reaction} to your paid note',
			'userReactedYourMessage' => ({required Object name, required Object reaction}) => '${name} reacted ${reaction} to your message',
			'userRepostedYourNote' => ({required Object name}) => '${name} reposted your note',
			'userRepostedYourPaidNote' => ({required Object name}) => '${name} reposted your paid note',
			'userRepliedYourArticle' => ({required Object name}) => '${name} replied to your article',
			'userRepliedYourCuration' => ({required Object name}) => '${name} replied to your curation',
			'userRepliedYourVideo' => ({required Object name}) => '${name} replied to your video',
			'userRepliedYourSmartWidget' => ({required Object name}) => '${name} replied to your smart widget',
			'userRepliedYourPoll' => ({required Object name}) => '${name} replied to your poll',
			'userRepliedYourNote' => ({required Object name}) => '${name} replied to your note',
			'userRepliedYourPaidNote' => ({required Object name}) => '${name} replied to your paid note',
			'userCommentedYourArticle' => ({required Object name}) => '${name} commented on your article',
			'userCommentedYourCuration' => ({required Object name}) => '${name} commented on your curation',
			'userCommentedYourVideo' => ({required Object name}) => '${name} commented on your video',
			'userCommentedYourSmartWidget' => ({required Object name}) => '${name} commented on your smart widget',
			'userCommentedYourPoll' => ({required Object name}) => '${name} commented on your poll',
			'userCommentedYourNote' => ({required Object name}) => '${name} commented on your note',
			'userCommentedYourPaidNote' => ({required Object name}) => '${name} commented on your paid note',
			'userQuotedYourArticle' => ({required Object name}) => '${name} quoted your article',
			'userQuotedYourCuration' => ({required Object name}) => '${name} quoted your curation',
			'userQuotedYourVideo' => ({required Object name}) => '${name} quoted your video',
			'userQuotedYourNote' => ({required Object name}) => '${name} quoted your note',
			'userQuotedYourPaidNote' => ({required Object name}) => '${name} quoted your paid note',
			'userReactedArticleYouIn' => ({required Object name, required Object reaction}) => '${name} reacted ${reaction} to an article you were mentioned in',
			'userReactedCurationYouIn' => ({required Object name, required Object reaction}) => '${name} reacted ${reaction} to a curation you were mentioned in',
			'userReactedVideoYouIn' => ({required Object name, required Object reaction}) => '${name} reacted ${reaction} to a video you were mentioned in',
			'userReactedSmartWidgetYouIn' => ({required Object name, required Object reaction}) => '${name} reacted ${reaction} to a smart widget you were mentioned in',
			'userReactedPollYouIn' => ({required Object name, required Object reaction}) => '${name} reacted ${reaction} to a poll you were mentioned in',
			'userReactedNoteYouIn' => ({required Object name, required Object reaction}) => '${name} reacted ${reaction} to a note you were mentioned in',
			'userReactedPaidNoteYouIn' => ({required Object name, required Object reaction}) => '${name} reacted ${reaction} to a paid note you were mentioned in',
			'userRepostedNoteYouIn' => ({required Object name}) => '${name} reposted a note you were mentioned in',
			'userRepostedPaidNoteYouIn' => ({required Object name}) => '${name} reposted a paid note you were mentioned in',
			'userRepliedArticleYouIn' => ({required Object name}) => '${name} replied to a article you were mentioned in',
			'userRepliedCurationYouIn' => ({required Object name}) => '${name} replied to a curation you were mentioned in',
			'userRepliedVideoYouIn' => ({required Object name}) => '${name} replied to a video you were mentioned in',
			'userRepliedSmartWidgetYouIn' => ({required Object name}) => '${name} replied to a smart widget you were mentioned in',
			'userRepliedPollYouIn' => ({required Object name}) => '${name} replied to a poll you were mentioned in',
			'userRepliedNoteYouIn' => ({required Object name}) => '${name} replied to a note you were mentioned in',
			'userRepliedPaidNoteYouIn' => ({required Object name}) => '${name} replied to a paid note you were mentioned in',
			'userCommentedArticleYouIn' => ({required Object name}) => '${name} commented on an article you were mentioned in',
			'userCommentedCurationYouIn' => ({required Object name}) => '${name} commented on a curation you were mentioned in',
			'userCommentedVideoYouIn' => ({required Object name}) => '${name} commented on a video you were mentioned in',
			'userCommentedSmartWidgetYouIn' => ({required Object name}) => '${name} commented on a smart you were mentioned in widget',
			'userCommentedPollYouIn' => ({required Object name}) => '${name} commented on a poll you were mentioned in',
			'userCommentedNoteYouIn' => ({required Object name}) => '${name} commented on a note you were mentioned in',
			'userCommentedPaidNoteYouIn' => ({required Object name}) => '${name} commented on a paid you were mentioned in note',
			'userQuotedArticleYouIn' => ({required Object name}) => '${name} quoted an article you were mentioned in',
			'userQuotedCurationYouIn' => ({required Object name}) => '${name} quoted a curation you were mentioned in',
			'userQuotedVideoYouIn' => ({required Object name}) => '${name} quoted a video you were mentioned in',
			'userQuotedNoteYouIn' => ({required Object name}) => '${name} quoted a note you were mentioned in',
			'userQuotedPaidNoteYouIn' => ({required Object name}) => '${name} quoted a paid note you were mentioned in',
			'reactedWith' => ({required Object name, required Object reaction}) => '${name} reacted with ${reaction}',
			'verifiedNoteSealed' => 'Your verified note has been sealed.',
			'verifiedNoteRateSealed' => 'An verified note you have rated has been sealed.',
			'userNewVideo' => ({required Object name}) => '${name}\'s video',
			'titleData' => ({required Object description}) => 'Title: ${description}',
			'checkoutVideo' => 'checkout my video',
			'yakihonneNotification' => 'YakiHonne\'s notification',
			'unknownVerifiedNote' => 'Unknown\'s verified note',
			'userReply' => ({required Object name}) => '${name}\'s replied',
			'userPaidNote' => ({required Object name}) => '${name}\'s new paid note',
			'contentData' => ({required Object description}) => 'Content: ${description}',
			'checkoutPaidNote' => 'check out my paid note',
			'userNewCuration' => ({required Object name}) => '${name}\'s new curation',
			'userNewArticle' => ({required Object name}) => '${name}\'s new article',
			'userNewSmartWidget' => ({required Object name}) => '${name}\'s new smart widget',
			'checkoutArticle' => 'check out my article',
			'checkoutCuration' => 'check out my curation',
			'checkoutSmartWidget' => 'check out my smart widget',
			'languagePreferences' => 'Language preferences',
			'contentTranslation' => 'Content Translation',
			'appLanguage' => 'App language',
			'apiKeyRequired' => 'Api key (required)',
			'getApiKey' => 'Get API Key',
			'seeTranslation' => 'See translation',
			'seeOriginal' => 'See original',
			'plan' => 'Plan',
			'free' => 'Free',
			'pro' => 'Pro',
			'errorTranslating' => 'Error occured while translating content.',
			'errorMissingKey' => 'Missing API Key or expired subscription. Check Settings -> Language Preferences for more.',
			'comingSoon' => 'Coming soon',
			'content' => 'Content',
			'expiresOn' => ({required Object date}) => 'Expires on: ${date}',
			'collapseNote' => 'Collapse note',
			'reactions' => 'Reactions',
			'reposts' => 'Reposts',
			'notifDisabled' => 'Notifications are disabled!',
			'notifDisabledMessage' => 'Notifications are disabled for this type, you can enable it in the notifications settings.',
			'oneNotifOptionAvailable' => 'There should be at least one notification option available.',
			'readAll' => 'Read all',
			'usernameTaken' => 'Username is taken',
			'usernameRequired' => 'Username is required',
			'deleteWalletConfirmation' => 'Please ensure you securely save your NWC connection phrase, as we cannot assist with recovering lost wallets.',
			'unsupportedKind' => 'Unsupported kind',
			'analyticsCrashlytics' => 'Crashlytics',
			'analyticsCache' => 'Crashlytics & cache',
			'analyticsCacheOn' => 'Crashlytics have been turned on.',
			'analyticsCacheOff' => 'Crashlytics have been turned off.',
			'shareNoUsage' => 'You share no crashlytics with us at the moment.',
			'wantShareAnalytics' => 'Want to share crashlytics?',
			'yakihonneAnCr' => 'YakiHonne\'s crashlytics',
			'crashlyticsTerms' => 'Collecting anonymized crashlytics is vital for refining our app\'s features and user experience. It enables us to identify user preferences, enhance popular features, and make informed optimizations, ensuring a more personalized and efficient app for our users.',
			'collectAnonymised' => 'We collect anonymised crashlytics to improve the app experience.',
			'linkWalletToProfile' => 'Link wallet with your profile',
			'linkWalletToProfileDesc' => 'The linked wallet is going to be used to receive sats',
			'noWalletLinked' => 'You have no wallet linked to your profile consider linking one of yours in the menu above',
			'addPoll' => 'Add poll',
			'browsePolls' => 'Browse polls',
			'maciPolls' => 'MACI poll',
			'beta' => 'Beta',
			'choosePollType' => 'Choose a poll type',
			'created' => 'Created',
			'tallying' => 'Tallying',
			'ended' => 'Ended',
			'closed' => 'Closed',
			'voteResultsBy' => 'Vote results by',
			'votes' => 'votes',
			'voiceCredit' => 'Voice credit',
			'viewDetails' => 'View details',
			'signup' => 'Signup',
			'notDownloadProof' => 'Could not download proofs',
			'name' => 'Name',
			'status' => 'Status',
			'circuit' => 'Circuit',
			'votingSystem' => 'Voting system',
			'proofSystem' => 'Proof system',
			'gasStation' => 'Gas station',
			'totalFund' => '(total fund)',
			'roundStart' => 'Round start',
			'roundEnd' => 'Round end',
			'operator' => 'Operator',
			'contractCreator' => 'Contract creator',
			'contractAddress' => 'Contract address',
			'blockHeight' => 'Block height',
			'atContractCreation' => ({required Object number}) => '${number} (at contract creation)',
			'zkProofs' => 'ZK proofs',
			'downloadZkProofs' => 'Download proofs',
			'walletConnectionString' => 'Wallet Connection String',
			'walletConnectionStringDesc' => 'Please make sure to securely copy or export your wallet connection string. We do not store this information, and if lost, it cannot be recovered.',
			'export' => 'Export',
			'logout' => 'Log out',
			'exportAndLogout' => 'Export & log out',
			'exportWalletsDesc' => 'It looks like you have wallets linked to your account. Please download your wallet secrets before logging out.',
			'manageWallets' => 'Manage wallets',
			'roundDuration' => 'Round duration',
			'startAt' => ({required Object date}) => 'Starts at: ${date}',
			'loginAction' => 'Log in',
			'addPicture' => 'Add picture',
			'editPicture' => 'Edit picture',
			'exportKeys' => 'Export keys',
			'mutedUser' => 'Muted user',
			'unaccessibleContent' => 'Inaccessible content',
			'mutedUserDesc' => 'You have muted this user, consider unmuting to view this content',
			'commentHidden' => 'This comment is hidden',
			'upcoming' => 'Upcoming',
			_ => null,
		};
	}

	dynamic _flatMapFunction$2(String path) {
		return switch (path) {
			'exportCredentials' => 'Export credentials',
			'loginToYakihonne' => 'Log in to Yakihonne',
			'alreadyUser' => 'Already a user?',
			'createPoll' => 'Create poll',
			'gasStationTotal' => 'Gas station (total funded)',
			'gasStationRemaining' => 'Gas station (remaining balance)',
			'paste' => 'Paste',
			'manual' => 'Manual',
			'contacts' => 'Contacts',
			'typeManualDesc' => 'Type lightning Address, Lightning invoice or LNURL',
			'useValidPaymentRequest' => 'Please use valid payment request',
			'save' => 'Save',
			'saveImageGallery' => 'Image has been downloaded to your gallery',
			'errorSavingImage' => 'Error occured while downloading the image',
			'copyImageGallery' => 'Image has been copied to your Clipboard',
			'errorCopyImage' => 'Error occured while copying the image',
			'scan' => 'Scan',
			'invalidLightningAddress' => 'Invalid lightning address',
			'deleteAccountDesc' => 'You are about to delete your account, do you wish to proceed?',
			'paymentFailedInvoice' => 'Payment failed: check the validity of this invoice',
			'validSatsAmount' => 'Set a valid sats amount',
			'placeholder' => 'Placeholder',
			'inputFieldCustomization' => 'Input field customization',
			'addInputField' => 'Add input field',
			'addButton' => 'Add button',
			'selectImage' => 'Select image',
			'moveLeft' => 'Move left',
			'moveRight' => 'Move right',
			'buttonRequired' => 'There should be at least one button available',
			'missingInputDesc' => 'It looks like you\'re using one of the custom functions that requires an input field component without embedding one in your smart widget, please add an input field so the function works properly.',
			'countdown' => 'Countdown',
			'contentEndsAt' => 'Content ends at',
			'countdownTime' => 'Countdown time is mandatory',
			'contentEndsDate' => 'Content ends date is mandatory',
			'lnMandatory' => 'Lightning address is mandatory',
			'pubkeysMandatory' => 'At least one profile is mandatory',
			'buttonNoUrl' => 'Buttons urls are mandatory',
			'shareWidgetImage' => 'Share widget image',
			'inputField' => 'Input field',
			'noReplies' => 'No replies',
			'message' => 'Message',
			'chat' => 'Chat',
			'onlyLettersNumber' => 'Only letters & numbers allowed',
			'appCache' => 'App cache',
			'cachedData' => 'Cached data',
			'cachedMedia' => 'Cached media',
			'cacheCleared' => 'Cache has been cleared',
			'closeAppClearingCache' => 'It is preferable to restart the app upon clearing cache to ensure all changes take effect and the app runs smoothly',
			'appCacheNotice' => 'Your app cache is growing in size. To ensure smooth performance, it\'s recommended to clear old data.',
			'manageCache' => 'Manage cache',
			'filterByTime' => 'Filter by time',
			'allTime' => 'All time',
			'oneMonth' => '1 month',
			'threeMonths' => '3 months',
			'sixMonths' => '6 months',
			'oneYear' => '1 year',
			'defaultZapAmount' => 'Default zap amount',
			'oneTapZap' => 'Enable one tap zap',
			'verify' => 'Verify',
			'reset' => 'reset',
			'appCannotVerified' => 'App cannot be verified or invalid',
			'useValidAppUrl' => 'Use a valid app url',
			'app' => 'App',
			'userNotConnected' => 'User not connected',
			'userCannotSignEvent' => 'This user cannot sign events.',
			'invalidEvent' => 'Invalid event',
			'eventCannotBeSigned' => 'Event cannot be signed',
			'signEvent' => 'Sign event',
			'sign' => 'Sign',
			'signPublish' => 'Sign & publish',
			'signEventDes' => 'You are about to sign the following event',
			'enableAutomaticSigning' => 'Automatic signing',
			'tools' => 'Tools',
			'searchSmartWidgets' => 'Search for smart widgets',
			'noToolsAvailable' => 'No tools available',
			'underMaintenance' => 'Under maintenance',
			'smartWidgetMaintenance' => 'Smart Widget is down for maintenance. We\'re fixing it up and will have it back soon!',
			'mySavedTools' => 'My saved tools',
			'availableTools' => 'Available tools',
			'remove' => 'Remove',
			'youHaveNoTools' => 'You have no tools',
			'discoverTools' => 'Discover published tools to help you with your content creation',
			'addWidgetTools' => 'Add widget tools',
			'widgetSearch' => 'Widget search',
			'widgetSearchDesc' => 'searching for published smart widgets and what people made',
			'getInspired' => 'Get inspired',
			'getInspirtedDesc' => 'ask our AI to help you build your smart widget',
			'trySearch' => 'Try out different methods of searching',
			'typeForCommands' => 'Type / for commands',
			'loadMore' => 'Load more',
			'searchingFor' => ({required Object name}) => 'Search for: ${name}',
			'playground' => 'Playground',
			'typeKeywords' => 'Type keywords (ie: Keyword1, Keyword2..)',
			'enableGossip' => 'Gossip model',
			'enableGossipDesc' => 'Gossip model is disabled by default. You can enable it, in Settings, under Content moderation.',
			'enableExternalBrowser' => 'Use external browser',
			'restartAppTakeEffect' => 'Restart the app for the action to take effect',
			'tips' => 'Tips',
			'docs' => 'Docs',
			'tryMiniApp' => 'Try out your mini-app with hands-on, interactive testing.',
			'exploreOurRepos' => 'Explore our repos or check our Smart Widgets docs.',
			'bringAi' => 'We\'re bringing AI!',
			'bringAiDesc' => 'We\'re crafting an AI assistant to streamline your work with programmable widgets and mini-app development—keep an eye out!',
			'notesCount' => ({required Object number}) => '${number} note(s)',
			'mixedContentCount' => ({required Object number}) => '${number} content',
			'noApp' => 'No suited app can be found to open the exported file',
			'andMore' => ({required Object number}) => '& ${number} other(s)',
			'addFilter' => 'Add filter',
			'entitleFilter' => 'Entitle of filter',
			'includedWords' => 'Included words',
			'excludedWords' => 'Excluded words',
			'hideSensitiveContent' => 'Hide sensitive content',
			'mustIncludeThumbnail' => 'Must include thumbnail',
			'forArticles' => 'For articles',
			'forVideos' => 'For videos',
			'forCurations' => 'For curations',
			'articleMinWords' => 'Content minimum words count',
			'showOnlyArticleMedia' => 'Show only articles with media',
			'showOnlyNotesMedia' => 'Show only notes with media',
			'curationsType' => 'Curations type',
			'minItemCount' => 'Minimum items count',
			'addWord' => 'Add a proper word',
			'wordNotInIncluded' => 'Make sure the word is not in the included words',
			'wordNotInExcluded' => 'Make sure the word is not in the excluded words',
			'fieldRequired' => 'Field required',
			'filterAdded' => 'Filter has been added',
			'filterUpdated' => 'Filter has been updated',
			'filterDeleted' => 'Filter has been deleted',
			'filters' => 'Filters',
			'contentFeed' => 'Content feed',
			'communityFeed' => 'Community feed',
			'relaysFeed' => 'Relays feed',
			'marketplaceFeed' => 'Marketplace feed',
			'addYourFeed' => 'Add your preferred feed',
			'myList' => 'My list',
			'allFreeFeeds' => 'All free feeds',
			'noRelays' => 'No relays are present',
			'addRelays' => 'Add your relay list to enjoy a clean and custom feed',
			'adjustYourFeedList' => 'Adjust your feed list',
			'addRelayUrl' => 'Add relay url',
			'feedOptionEnabled' => 'At least one feed option should be enabled',
			'feedSetUpdate' => 'Feed set has been updated',
			'global' => 'Global',
			'fromNetwork' => 'From network',
			'top' => 'Top',
			'showFollowingList' => 'Your current feed is based on someone else\'s following list, start following people to tailor your feed on your preference',
			'from' => 'From',
			'to' => 'To',
			'dayMonthYear' => 'dd/MM/yyyy',
			'fromDateMessage' => '\'From\' date must be earlier than \'To\' date',
			'toDateMessage' => '\'To\' date must be later than \'From\' date',
			'noResults' => 'No results',
			'noResultsFilterMessage' => 'It looks like you\'re applying a custom filter, please adjust the parameters and dates to acquire more data',
			'noResultsNoFilterMessage' => 'Nothing was found, please change your content source or apply different filter params',
			'addToNotes' => 'Add to notes',
			'addToDiscover' => 'Add to discover',
			'shareRelayContent' => 'Share relay content',
			'shareRelayUrl' => 'Share relay URL',
			'basic' => 'Basic',
			'privateMessages' => 'Private messages',
			'pushNotifications' => 'Push notifications',
			'repliesView' => 'Replies view',
			'threadView' => 'Thread',
			'boxView' => 'Box',
			'viewAs' => 'View as',
			'feedSettings' => 'Feed settings',
			'appliedFilterDesc' => 'This note is hidden due to the current applied filter.',
			'showNote' => 'Show note',
			'allMedia' => 'All media',
			'searchInNostr' => 'Search in Nostr',
			'findPeopleContent' => 'Find people, notes & content',
			'activeService' => 'Active service',
			'regularServers' => 'Regular servers',
			'blossomServers' => 'BLOSSOM servers',
			'mirrorAllServer' => 'Mirror all servers',
			'mainServer' => 'Main server',
			'select' => 'Select',
			'noServerFound' => 'No server found',
			'serverExists' => 'Server already exists on your list',
			'invalidUrl' => 'Invalid url format',
			'serverPath' => 'Server path',
			'errorAddingBlossom' => 'Error occured while adding blossom server',
			'errorSelectBlossom' => 'Error occured while selecting blossom server',
			'errorDeleteBlossom' => 'Error occured while deleting blossom server',
			'wotConfig' => 'Web of trust configuration',
			'wot' => 'web of trust',
			'wotThreshold' => 'Web of trust threshold',
			'postActions' => 'Post actions',
			'enabledFor' => 'Enabled for',
			'dmRelayTitle' => 'Private messages relays are not configured!',
			'dmRelayDesc' => 'Update your relays list accordingly. ',
			'youFollow' => 'You follow',
			'quotaLimit' => 'You have exceeded your daily quota limit',
			'alwaysUseExternal' => 'Always use external wallet zaps',
			'alwaysUseExternalDesc' => 'Use an external Lightning wallet app instead of YakiHonne\'s built-in wallet for all zap transactions.',
			'unreachableExternalWallet' => 'Unreachable external wallet',
			'secureStorageDesc' => 'Your keys are stored securely on your device and never shared with us or anyone else.',
			'pubkeySharedDesc' => 'Safe to share - this identifies you on Nostr.',
			'privKeyDesc' => 'Keep private - backup securely to access your account elsewhere.',
			'settingsKeysDesc' => 'Manage your Nostr keys for network identity, event signing, and post authentication.',
			'settingsRelaysDesc' => 'Configure Nostr relay connections for storing and distributing events.',
			'settingsCustomizationDesc' => 'Personalize your YakiHonne feed display, gestures, previews, and preferences for better Nostr experience.',
			'settingsNotificationsDesc' => 'Control notifications for messages, mentions, reactions, and other Nostr events.',
			'settingsContentDesc' => 'Control content interactions, privacy settings, media handling, and messaging preferences on Nostr.',
			'settingsLanguageDesc' => 'Choose your preferred language for YakiHonne interface and content translation.',
			'settingsWalletDesc' => 'Connect and manage Bitcoin Lightning wallets for sending/receiving zaps with customizable amounts and external integration.',
			'settingsAppearanceDesc' => 'Customize YakiHonne\'s visual appearance to match your preferences and viewing comfort.',
			'settingsCacheDesc' => 'Manage app performance monitoring, error reporting, and storage optimization for smooth operation.',
			'addQuickRelayDesc' => 'Quickly add a new relay by entering its URL.',
			'fewerRelays' => 'Fewer stable relays = better performance and faster syncing.',
			'greenDotsDesc' => 'Green dots show active connections.',
			'redDotsDesc' => 'Red dots show offline relays.',
			'greyDotsDesc' => 'Grey dots show pending relays.',
			'homeFeedCustomDesc' => 'Choose reply display style (Box or Thread) and manage suggestion preferences for people, content, and interests.',
			'NewPostDesc' => 'Choose what happens when you long-press while creating posts (currently set to Note).',
			'profilePreviewDesc' => 'Show user profile previews when tapping usernames in your feed.',
			'collapseNoteDesc' => 'Automatically minimize long posts to keep your feed clean and readable.',
			'pushNotificationsDesc' => 'Get instant alerts on your device. Privacy-focused using secure FCM and APNS protocols',
			'privateMessagesDesc' => 'Get alerted for new direct messages and private conversations.',
			'followingDesc' => 'Get notified when people you follow post new content.',
			'mentionsDesc' => 'Get alerted when someone mentions you or replies to your posts.',
			'repostsDesc' => 'Get alerted when someone shares or reposts your content.',
			'reactionsDesc' => 'Get notified when some likes or react to your posts.',
			'zapDesc' => 'Get notified when you receive Bitcoin tips (zaps) on your posts.',
			'muteListDesc' => 'View and manage users you\'ve blocked from appearing in your feed.',
			'mediaUploaderDesc' => 'Choose which service uploads your images and media files.',
			'autoSignDesc' => 'Automatically sign events requested by mini apps (action/tool smart widgets) without manual confirmation each time.',
			'gossipDesc' => 'Sophisticated relay management that automatically finds your followees\' posts across different relays while minimizing connections and adapting to offline relays.',
			'useExternalBrowsDesc' => 'Open links in your default browser app instead of the built-in browser.',
			'secureDmDesc' => 'Use the latest private messaging standard (NIP-17) with advanced encryption. Disable to use the older NIP-4 format for compatibility.',
			'wotConfigDesc' => 'A decentralized trust mechanism using social attestations to establish reputation within the Nostr protocol.',
			'appLangDesc' => 'Choose the language for YakiHonne\'s interface, menus, and buttons.',
			'contentTransDesc' => 'Select translation service for posts in foreign languages.',
			'planDesc' => 'Your current translation plan tier and usage limits.',
			'manageWalletsDesc' => 'Add and organize your Lightning wallets for sending and receiving Bitcoin zaps on Nostr.',
			'defaultZapDesc' => 'Set the default Bitcoin amount (in sats) when sending quick zaps to posts.',
			'enableZapDesc' => 'One tap sends default amount instantly. Double tap opens zap options (amount, wallet, message). When disabled, double tap sends default amount.',
			'externalWalletDesc' => 'Use an external Lightning wallet app instead of YakiHonne\'s built-in wallet for all zap transactions.',
			'fontSizeDesc' => 'Adjust text size throughout the app for better readability - use the slider to make text larger or smaller.',
			'appThemeDesc' => 'Switch between light and dark mode to customize the app\'s visual appearance.',
			'crashlyticsDesc' => 'Anonymous crash reporting and app analytics to help improve performance and fix bugs. We use Umami analytics to improve your experience. Opt out anytime.',
			'showSuggDesc' => 'Display general content recommendations in your feed.',
			'showSuggPeople' => 'Show recommended users to follow based on your activity.',
			'showSuggContent' => 'Display recommended posts and articles in your feed.',
			'showSuggInterests' => 'Show topic and interest recommendations for discovery.',
			'striveToMake' => 'We strive to make the best out of Nostr, Support us below or send us your valuable feed: zap, dms, github.',
			'errorAmber' => 'You either rejected or you are already connected with amber',
			'useOneRelay' => 'You should at least leave one relay connected',
			'automaticPurge' => 'Automatic cache purge',
			'automaticPurgeDesc' => 'Auto-clear app cache when it reaches 2GB. Maintains performance and prevents excessive storage usage.',
			'customServices' => 'Custom services',
			'defaultServices' => 'Default services',
			'addService' => 'Add service',
			'customServicesDesc' => 'Available custom services added by you.',
			'urlRequired' => 'Url required',
			'serviceAdded' => 'Service has been added',
			'showRawEvent' => 'Show raw event',
			'rawEventData' => 'Raw event data',
			'copyRawEventData' => 'Raw event data was copied! 👏',
			'kind' => 'Kind',
			'shortNote' => 'Short note',
			'postedOnDate' => 'Posted on',
			'showMore' => '... show more',
			'accountDeleted' => 'This account has been deleted and can no longer be accessed.',
			'ok' => 'OK',
			'redeem' => 'Redeem',
			'redeemCode' => 'Redeem code',
			'redeemAndEarn' => 'Redeem & Earn',
			'redeemingFailed' => 'Redeeming failed',
			'redeemInProgress' => 'Redeeming code in progress...',
			'redeemCodeDesc' => 'Enter your code to redeem it',
			'missingCode' => 'Missing code',
			'missingPubkey' => 'Missing pubkey',
			'invalidPubkey' => 'Invalid pubkey',
			'missingLightningAddress' => 'Missing lightning address',
			'codeNotFound' => 'Code not found',
			'redeemCodeRequired' => 'Redeem code is required',
			'redeemCodeInvalid' => 'Redeem code is invalid',
			'codeBeingRedeemed' => 'Your code is being redeemed. If it doesn\'t complete successfully, please try again shortly.',
			'redeemCodeSuccess' => 'Code has been successfully redeemed',
			'redeemFailed' => 'Could not redeem the code, please try again later.',
			'codeAlreadyRedeemed' => 'Code has already been redeemed',
			'satsEarned' => ({required Object amount}) => '+${amount} sats earned.',
			'selectReceivingWallet' => 'Select receiving wallet',
			'redeemCodeMessage' => 'Claim free sats with YakiHonne redeemable codes — simply enter your code and boost your balance instantly.',
			'scanCode' => 'Scan code',
			'enterCode' => 'Enter code',
			'errorSharingMedia' => 'Error occured while sharing media',
			'open' => 'Open',
			'openUrl' => 'Open URL',
			'openUrlDesc' => ({required Object url}) => 'Do you want to open "${url}"?',
			'openUrlPrompt' => 'Open url prompt',
			'openUrlPromptDesc' => 'A safety prompt that displays the full URL before opening it in your browser.',
			'waitingForNetwork' => 'Waiting for network...',
			'whatsNew' => 'What\'s new',
			'appCustom' => 'App custom',
			'poll' => 'Poll',
			'pendingEvents' => 'Pending events',
			'pendingEventsDesc' => 'Pending events are created while offline or with poor connection. They\'ll be automatically sent when your internet connection is restored.',
			'singleColumnFeed' => 'Single column feed',
			'singleColumnFeedDesc' => 'Show the home feed as a single wide column for better readability.',
			'waitingPayment' => 'Waiting for payment',
			'copyId' => 'Copy id',
			'idCopied' => 'Id was copied! 👏',
			'republish' => 'Republish',
			'useRelayRepublish' => 'You should at least choose one relay to republish to.',
			'republishSucces' => 'Event has been republished successfully!',
			'errorRepublishEvent' => 'Error occured while republishing event',
			'remoteSigner' => 'Remote signer',
			'amber' => 'Amber',
			'useUrlBunker' => 'Use the below URL to connect to your bunker',
			'or' => 'Or',
			'messagesDisabled' => 'Messages are disabled',
			'messagesDisabledDesc' => 'You are connected with a remote signer. Direct messages may contain large amounts of data and might not work properly. For the best experience, please use a local signer to enable direct messaging.',
			'sharedOn' => ({required Object date}) => 'Shared on ${date}',
			'shareAsImage' => 'Share as image',
			'viewOptions' => 'View options',
			'feedCustomization' => 'Feed customization',
			'defaultReaction' => 'Default reaction',
			'defaultReactionDesc' => 'Set a default reaction to react to posts.',
			'oneTapReaction' => 'Enable one tap reaction',
			'oneTapReactionDesc' => 'One tap react with the default reaction instantly. Double tap opens emojis list to choose from. When disabled, double tap sends default reaction',
			'sendingTo' => 'Sending to',
			'shareEmptyUsers' => 'Your followings list and friends will appear here for faster sharing experience',
			'publishOnly' => 'Publish only to',
			'protectedEvent' => 'Protected event',
			'protectedEventDesc' => 'A protected event is an event that only its author can republish. This keeps the content authentic and prevents others from copying or reissuing it.',
			'browseRelay' => 'Browse relay',
			'addFavorite' => 'Add favorite',
			'removeFavorite' => 'Remove favorite',
			'collections' => 'Collections',
			'online' => 'Online',
			'offline' => 'Offline',
			'network' => 'Network',
			'followedBy' => ({required Object number}) => 'Followed by ${number}',
			'favoredBy' => ({required Object number}) => 'Favored by ${number}',
			'requiredAuthentication' => 'Required authentication',
			'relayOrbits' => 'Relay orbits',
			'relayOrbitsDesc' => 'Browse and explore relay feeds',
			'people' => 'People',
			'youNotConnected' => 'You\'re not connected',
			'youNotConnectedDesc' => 'Log in to your account to browse your network relays',
			'checkingRelayConnectivity' => 'Checking relay connectivity',
			'unreachableRelay' => 'Unreachable relay',
			'engageWithUsers' => 'Engage to expand',
			'engageWithUsersDesc' => 'Engaging with more users helps you discover new relays and grow your relay list for a richer, more connected experience.',
			'loadingChatHistory' => 'Loading chat history...',
			'contentActionsOrder' => 'Content actions order',
			'contentActionsOrderDesc' => 'Easily rearrange your post interactions to match your preferred order.',
			'quotes' => 'Quotes',
			'eventLoading' => 'Event loading...',
			'loadMessages' => 'Load messages',
			'messagesNotLoaded' => 'Messages Not Loaded',
			'messagesNotLoadedDesc' => 'Messages are not loaded due to using a local remote signer, if you wish to load them, please click the button below.',
			'noteLoading' => 'Note loading...',
			'hideNonFollowedMedia' => 'Hide non-followed media',
			'hideNonFollowedMediaDesc' => 'Automatically hide images & videos from non-followed users until you tap to reveal.',
			'clickToView' => 'Click to view',
			'relayFeedListEmpty' => 'Relays feed list is empty',
			'relayFeedListEmptyDesc' => 'Add more relays to your list to enjoy a tailored feed.',
			'addRelay' => 'Add relays',
			'hiddenContent' => 'Hidden content',
			'hiddenContentDesc' => 'We\'ve hidden this content because you don\'t follow this account.',
			'enabledActions' => 'Enabled actions',
			'enabledActionsDesc' => 'No enabled actions available.',
			'fetchingNotificationEvent' => 'Fetching notification event',
			'notificationEventNotFound' => 'Notification event not found',
			'fiatCurrency' => 'Fiat currency',
			'fiatCurrencyDesc' => 'Convert sats into your selected fiat currency to better understand their value',
			'linkPreview' => 'Link preview',
			'linkPreviewDesc' => 'Toggle to display or hide previews for shared links in posts.',
			'muteThread' => 'Mute thread',
			'muteThreadDesc' => 'Your are about to mute the thread, do you wish to proceed?',
			'unmuteThread' => 'Unmute thread',
			'unmuteThreadDesc' => 'Your are about to unmute the thread, do you wish to proceed?',
			'threadMuted' => 'Thread has been muted',
			'threadUnmuted' => 'Thread has been unmuted',
			'noMutedEventsFound' => 'No muted events have been found.',
			'editCode' => 'Edit code',
			'previewCode' => 'Preview code',
			'liveCode' => 'Live code',
			'tag' => 'Tag',
			'quickConnectRelay' => 'Quick connect to relay',
			'exploreSearchRelays' => 'Explore search relays',
			'navigateToSearch' => 'Navigate & add active search relays',
			'errorSavingVideo' => 'Error occured while downloading the video',
			'saveVideoGallery' => 'Video has been downloaded to your gallery',
			'downloadingVideo' => 'Downloading video',
			'primaryColor' => 'Primary color',
			'primaryColorDesc' => 'Pick the accent color that shapes the app\'s overall mood and highlights key elements.',
			'single' => 'Single',
			'sets' => 'Sets',
			'selectFromRelaySets' => 'Select from your relay sets',
			'favoriteRelays' => 'Favorite relays',
			'favoriteRelaySets' => 'Favorite relay sets',
			'addRelaySet' => 'Add relay set',
			'updateRelaySet' => 'Update relay set',
			'relaySetCreated' => 'Relay set created',
			'errorOnCreatingRelaySet' => 'Error occured while creating relay set',
			'errorOnUpdatingRelaySet' => 'Error occured while updating relay set',
			'relaySetDeleted' => 'Relay set deleted',
			'errorDeletingRelaySet' => 'Error occured while deleting relay set',
			'relaysNumber' => ({required Object number}) => '${number} relays',
			'relaySetNotFound' => 'Relay set not found',
			'relaySetNotFoundDesc' => 'Relay set is missing or has been deleted.',
			'savedRelaySets' => 'Saved relay sets',
			'relaysets' => 'Relay sets',
			'relaySetListEmpty' => 'Relay set list is empty',
			'relaySetListEmptyDesc' => 'Create relay sets to organize your relays for different purposes and scenarios.',
			'favoriteRelaysFeed' => 'Favorite relays feed',
			'maxMentions' => 'Max mentions',
			'maxMentionsDesc' => 'Hide notifications from notes with more than 10 user mentions.',
			'media' => 'Media',
			'pinned' => 'Pinned',
			'pictures' => 'Pictures',
			'unpin' => 'Unpin',
			'pin' => 'Pin',
			'userPublishedPicture' => ({required Object name}) => '${name} published a picture',
			'userZappedYourPicture' => ({required Object name, required Object number}) => '${name} zapped your picture ${number} sats',
			'userReactedYourPicture' => ({required Object name, required Object reaction}) => '${name} reacted ${reaction} to your picture',
			'userReactedPictureYouIn' => ({required Object name, required Object reaction}) => '${name} reacted ${reaction} to a picture you were mentioned in',
			'userRepliedYourPicture' => ({required Object name}) => '${name} replied to your picture',
			'userRepliedPictureYouIn' => ({required Object name}) => '${name} replied to a picture you were mentioned in',
			'userMentionedYouInPicture' => ({required Object name}) => '${name} mentioned you in a picture',
			'userCommentedYourPicture' => ({required Object name}) => '${name} commented on your picture',
			'userCommentedPictureYouIn' => ({required Object name}) => '${name} commented on a picture you were mentioned in',
			'userQuotedYourPicture' => ({required Object name}) => '${name} quoted your picture',
			'userQuotedPictureYouIn' => ({required Object name}) => '${name} quoted a picture you were mentioned in',
			'cameraPermission' => 'Either the app does not have permission to access the camera or there are no cameras available on this device.',
			'fetchingPicture' => 'Fetching picture...',
			'addDescription' => 'Add description...',
			'uploadingVideo' => 'Uploading video...',
			'uploadThumbnail' => 'Upload thumbnail',
			'chooseThumbnailVideo' => 'Choose a proper thumbnail for your video',
			'publishing' => 'Publishing...',
			'giveMeCatchyTitle' => 'Give me a catchy title',
			_ => null,
		};
	}
}

