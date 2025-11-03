///
/// Generated file. Do not edit.
///
// coverage:ignore-file
// ignore_for_file: type=lint, unused_import

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
}

/// Flat map(s) containing all translations.
/// Only for edge cases! For simple maps, use the map function of this library.
extension on Translations {
	dynamic _flatMapFunction(String path) {
		switch (path) {
			case 'addNewBookmark': return 'No bookmarks list can be found, try to add one!';
			case 'setBookmarkTitleDescription': return 'Set a title & a description for your bookmark list.';
			case 'title': return 'title';
			case 'description': return 'description';
			case 'descriptionOptional': return 'description (optional)';
			case 'bookmarkLists': return 'Bookmark lists';
			case 'submit': return 'submit';
			case 'addBookmarkList': return 'Add bookmark list';
			case 'submitBookmarkList': return 'Submit bookmark list';
			case 'next': return 'next';
			case 'saveDraft': return 'Save draft';
			case 'deleteDraft': return 'Delete draft';
			case 'publish': return 'publish';
			case 'smHaveOneWidget': return 'The smart widget should have atleast one component.';
			case 'smHaveTitle': return 'The smart widget should at least have a title';
			case 'whatsOnYourMind': return 'What\'s on your mind?';
			case 'sensitiveContent': return 'This is a sensitive content';
			case 'addYourTopics': return 'Add your topics';
			case 'article': return 'article';
			case 'articles': return 'articles';
			case 'video': return 'video';
			case 'videos': return 'videos';
			case 'curation': return 'curation';
			case 'curations': return 'curations';
			case 'thumbnailPreview': return 'Thumbnail preview';
			case 'selectAndUploadLocaleImage': return 'Select & upload a local image';
			case 'issueOccuredSelectingImage': return 'Issue occured while selecting the image.';
			case 'imageUploadHistory': return 'Images upload history';
			case 'noImageHistory': return 'No images history has been found';
			case 'cancel': return 'cancel';
			case 'uploadAndUse': return 'Upload & use';
			case 'publishRemoveDraft': return 'Publish and remove the draft';
			case 'clearChat': return 'Clear chat';
			case 'noDataFromGpt': return 'There are data to show from GPT.';
			case 'askMeSomething': return 'Ask me something!';
			case 'copy': return 'copy';
			case 'textSuccesfulyCopied': return 'Text successfully copied!';
			case 'insertText': return 'Insert text';
			case 'searchContentByTitle': return ({required Object type}) => 'Search ${type} by title';
			case 'noContentCanBeFound': return ({required Object type}) => 'No ${type} can be found';
			case 'noContentBelongToCuration': return ({required Object type}) => 'No ${type} belong to this curation';
			case 'byPerson': return ({required Object name}) => 'By ${name}';
			case 'allRelays': return 'All relays';
			case 'myArticles': return 'My articles';
			case 'myVideos': return 'My videos';
			case 'curationType': return 'Curation type';
			case 'update': return 'update';
			case 'invalidInvoiceLnurl': return 'Make sure to set a valid invoice or lnurl';
			case 'addValidUrl': return 'Make sure to add a valid url';
			case 'layoutCustomization': return 'Layout customization';
			case 'duoLayout': return 'Duolayout';
			case 'monoLayout': return 'MonoLayout';
			case 'warning': return 'warning';
			case 'switchToMonolayout': return 'You\'re switching to a mono layout whilst having elements on both sides, this will erase the container content, do you wish to proceed?';
			case 'erase': return 'erase';
			case 'textCustomization': return 'Text customization';
			case 'writeYourText': return 'Write your text';
			case 'size': return 'size';
			case 'weight': return 'weight';
			case 'color': return 'color';
			case 'videoCustomization': return 'Video customization';
			case 'videoUrl': return 'Video url';
			case 'zapPollCustomization': return 'Zap poll customization';
			case 'contentTextColor': return 'Content text color';
			case 'optionTextColor': return 'Option text color';
			case 'optionBackgroundColor': return 'Option background color';
			case 'fillColor': return 'Fill color';
			case 'imageCustomization': return 'Image customization';
			case 'imageUrl': return 'Image url';
			case 'imageAspectRatio': return 'Image aspect ratio';
			case 'buttonCustomization': return 'Button customization';
			case 'buttonText': return 'Button text';
			case 'type': return 'type';
			case 'useInvoice': return 'Use invoice';
			case 'invoice': return 'invoice';
			case 'lightningAddress': return 'Lightning address';
			case 'selectUserToZap': return 'Select a user to zap (optional)';
			case 'zapPollNevent': return 'Zap poll nevent';
			case 'textColor': return 'Text color';
			case 'buttonColor': return 'Button color';
			case 'url': return 'Url';
			case 'invoiceOrLN': return 'Invoice or Lightning address';
			case 'youtubeUrl': return 'Youtube url';
			case 'telegramUrl': return 'Telegram Url';
			case 'xUrl': return 'X url';
			case 'discordUrl': return 'Discord url';
			case 'nostrScheme': return 'Nostr Scheme';
			case 'containerCustomization': return 'Container customization';
			case 'backgroundColor': return 'Background color';
			case 'borderColor': return 'Border color';
			case 'value': return 'value';
			case 'pickYourComponent': return 'Pick your component';
			case 'selectComponent': return 'Select the component at convience and edit it.';
			case 'text': return 'text';
			case 'image': return 'image';
			case 'button': return 'button';
			case 'summaryOptional': return 'Summary (Optional)';
			case 'smartWidgetsDrafts': return 'Smart widgets drafts';
			case 'noSmartWidget': return 'No smart widgets drafts can be found';
			case 'noSmartWidgetCanBeFound': return 'No smart widgets can be found';
			case 'smartWidgetConvention': return 'This smart widget does not follow the agreed on convention.';
			case 'monolayoutRequired': return 'Monolayout is required';
			case 'zapPoll': return 'Zap poll';
			case 'layout': return 'layout';
			case 'container': return 'container';
			case 'edit': return 'edit';
			case 'moveUp': return 'Move up';
			case 'moveDown': return 'Move down';
			case 'delete': return 'delete';
			case 'editToAddZapPoll': return 'Edit to add zap poll';
			case 'options': return 'options';
			case 'smartWidgetBuilder': return 'Smart widget builder';
			case 'startBuildingSmartWidget': return 'Start building and customize your smart widget to use on the Nostr network';
			case 'blankWidget': return 'Blank widget';
			case 'myDrafts': return 'My drafts';
			case 'templates': return 'templates';
			case 'communityPolls': return 'Community polls';
			case 'myPolls': return 'My polls';
			case 'noPollsCanBeFound': return 'No polls can be found';
			case 'totalNumber': return ({required Object number}) => 'Total: ${number}';
			case 'smartWidgetsTemplates': return 'Smart widgets templates';
			case 'noTemplatesCanBeFound': return 'No templates can be found in this category.';
			case 'useTemplate': return 'Use template';
			case 'pickYourVideo': return 'Pick your video';
			case 'canUploadPastLink': return 'You can upload, paste a link or choose a kind 1063 nevent to your video.';
			case 'gallery': return 'Gallery';
			case 'link': return 'Link';
			case 'fileSharing': return 'File sharing';
			case 'setUpYourLink': return 'Set up your link';
			case 'setUpYourNevent': return 'Set up your nevent';
			case 'pasteYourLink': return 'Paste your link and submit it';
			case 'pasteKind1063': return 'Paste your kind 1063 nevent and submit it';
			case 'addUrlNevent': return 'Add a proper url/nevent';
			case 'nevent': return 'nevent';
			case 'addProperUrlNevent': return 'Add a proper url/nevent';
			case 'horizontalVideo': return 'Horizontal video';
			case 'preview': return 'Preview';
			case 'writeSummary': return 'Write a summary';
			case 'uploadImage': return 'Upload image';
			case 'addToCuration': return 'Add to curation';
			case 'submitCuration': return 'Submit curation';
			case 'selectValidUrlImage': return 'Select a valid url image.';
			case 'noCurationsFound': return 'No curations have been found. Try to create one in order to be able to add content to it.';
			case 'availableArticles': return ({required Object number}) => '${number} available article(s)';
			case 'availableVideos': return ({required Object number}) => '${number} available video(s)';
			case 'articlesNum': return ({required Object number}) => '${number} article(s)';
			case 'videosNum': return ({required Object number}) => '${number} video(s)';
			case 'articlesAvailableCuration': return 'Articles available on this curation';
			case 'videosAvailableCuration': return 'Videos available on this curation';
			case 'articleAddedCuration': return 'Article has been added to your curation.';
			case 'videoAddedCuration': return 'Video has been added to your curation.';
			case 'validTitleCuration': return 'Make sure to add a valid title for this curation';
			case 'validDescriptionCuration': return 'Make sure to add a valid description for this curation';
			case 'validImageCuration': return 'Make sure to add a valid image for this curation';
			case 'addCuration': return 'Add curation';
			case 'postedBy': return 'Posted by';
			case 'follow': return 'follow';
			case 'unfollow': return 'unfollow';
			case 'postedFrom': return 'posted from';
			case 'noTitle': return 'No title';
			case 'itemsNumber': return ({required Object number}) => '${number} item(s)';
			case 'noArticlesInCuration': return 'No articles on this curation have been found';
			case 'noVideosInCuration': return 'No videos on this curation have been found';
			case 'add': return 'add';
			case 'noBookmarksListFound': return 'No booksmarks list were found, try to add one!';
			case 'deleteBookmarkList': return 'Delete bookmark list';
			case 'confirmDeleteBookmarkList': return 'You\'re about to delete this bookmarks list, do you wish to proceed?';
			case 'bookmarks': return 'Bookmarks';
			case 'bookmarksListCount': return ({required Object number}) => '${number} bookmarks lists';
			case 'noDescription': return 'No description';
			case 'editedOn': return ({required Object date}) => 'Edited on: ${date}';
			case 'publishedOn': return ({required Object date}) => 'Published on: ${date}';
			case 'publishedOnText': return 'Published on';
			case 'lastUpdatedOn': return ({required Object date}) => 'Last updated on: ${date}';
			case 'joinedOn': return ({required Object date}) => 'Joined on: ${date}';
			case 'list': return 'list';
			case 'noElementsInBookmarks': return 'No elements can be found in bookmarks list';
			case 'draft': return 'draft';
			case 'note': return 'note';
			case 'notes': return 'notes';
			case 'smartWidget': return 'Smart Widget';
			case 'widgets': return 'widgets';
			case 'postNote': return 'Post note';
			case 'postArticle': return 'Post article';
			case 'postCuration': return 'Post curation';
			case 'postVideo': return 'Post video';
			case 'postSmartWidget': return 'Post smart widget';
			case 'ongoing': return 'ongoing';
			case 'componentsSMCount': return ({required Object number}) => '${number} components in this widget';
			case 'share': return 'share';
			case 'copyNoteId': return 'Copy note ID';
			case 'noteIdCopied': return 'Note id was copied! 👏';
			case 'confirmDeleteDraft': return 'You\'re about to delete this draft, do you wish to proceed?';
			case 'reposted': return 'reposted';
			case 'postInNote': return 'Post in note';
			case 'clone': return 'clone';
			case 'checkValidity': return 'Check validity';
			case 'copyNaddr': return 'copy naddr';
			case 'deleteContent': return ({required Object type}) => 'Delete ${type}';
			case 'confirmDeleteContent': return ({required Object type}) => 'You\'re about to delete this ${type}, do you wish to proceed?';
			case 'home': return 'Home';
			case 'followings': return 'Followings';
			case 'followers': return 'Followers';
			case 'replies': return 'replies';
			case 'zapReceived': return 'Zaps received';
			case 'totalAmount': return 'Total amount';
			case 'zapSent': return 'Zaps sent';
			case 'latest': return 'latest';
			case 'saved': return 'saved';
			case 'seeAll': return 'See all';
			case 'popularNotes': return 'Popular notes';
			case 'getStartedNow': return 'Get started now';
			case 'expandWorld': return 'Expand the world by adding what fascinates you. Select your interests and let the journey begins';
			case 'addInterests': return 'Add interests';
			case 'manageInterests': return 'Manage interests';
			case 'interests': return 'interests';
			case 'yakihonneImprovements': return 'YakiHonne\'s improvements';
			case 'yakihonneNote': return 'YakiHonne\'s note';
			case 'privacyNote': return 'Our app guarantees the utmost privacy by securely storing sensitive data locally on users\' devices, employing stringent encryption. Rest assured, we uphold a strict no-sharing policy, ensuring that sensitive information remains confidential and never leaves the user\'s device.';
			case 'pickYourMedia': return 'Pick your media';
			case 'uploadSendMedia': return 'You can upload and send media right after your selection or taking them.';
			case 'noMessagesToDisplay': return 'No messages to be displayed.';
			case 'enableSecureDmsMessage': return 'For more security & privacy, consider enabling Secure DMs.';
			case 'replyingTo': return ({required Object name}) => 'Replying to: ${name}';
			case 'writeYourMessage': return 'Write a message';
			case 'zap': return 'zap';
			case 'disableSecureDms': return 'Disable Secure DMs';
			case 'enableSecureDms': return 'Enable Secure DMs';
			case 'notUsingSecureDms': return 'You are no longer using Secure Dms';
			case 'usingSecureDms': return 'You are now using Secure Dms';
			case 'mute': return 'mute';
			case 'unmute': return 'unmute';
			case 'muteUser': return 'Mute user';
			case 'unmuteUser': return 'Unmute user';
			case 'muteUserDesc': return ({required Object name}) => 'Your are about to mute ${name}, do you wish to proceed?';
			case 'unmuteUserDesc': return ({required Object name}) => 'Your are about to unmute ${name}, do you wish to proceed?';
			case 'messageCopied': return 'Message successfully copied!';
			case 'messageNotDecrypted': return 'Message has not been decrypted yet!';
			case 'reply': return 'reply';
			case 'newMessage': return 'New message';
			case 'searchNameNpub': return 'Search by name, npub, nprofile';
			case 'searchByUserName': return 'Search by username';
			case 'known': return 'Known';
			case 'unknown': return 'Unknown';
			case 'noMessageCanBeFound': return 'No messages can be found';
			case 'you': return 'You: ';
			case 'decrMessage': return 'Decrypting message';
			case 'gifs': return 'gifs';
			case 'stickers': return 'stickers';
			case 'customizeYourFeed': return 'Customize your feed';
			case 'feedOptions': return 'Feed options';
			case 'recent': return 'recent';
			case 'recentWithReplies': return 'Recent with replies';
			case 'explore': return 'explore';
			case 'following': return 'following';
			case 'trending': return 'trending';
			case 'highlights': return 'highlights';
			case 'paid': return 'paid';
			case 'others': return 'others';
			case 'suggestionsBox': return 'Suggestions box';
			case 'showSuggestions': return 'Show suggestions';
			case 'showSuggestedPeople': return 'Show suggested people to follow';
			case 'showArticlesNotesSuggestions': return 'Show articles/notes suggestions';
			case 'showSuggestedInterests': return 'Show suggested interests';
			case 'readTime': return ({required Object time}) => '${time}m read';
			case 'watchNow': return 'watch now';
			case 'bookmark': return 'bookmark';
			case 'suggestions': return 'Suggestions';
			case 'hideSuggestions': return 'Hide suggestions';
			case 'enjoyExpOwnData': return 'Enjoy the experience of owning\nyour own data!';
			case 'signIn': return 'Sign in';
			case 'createAccount': return 'Create account';
			case 'byContinuing': return 'By continuing you agree with our\n';
			case 'eula': return 'End User Licence Agreement (EULA)';
			case 'continueAsGuest': return 'Continue as a guest';
			case 'heyWelcomeBack': return 'Hey,\nWelcome\nBack';
			case 'npubNsecHex': return 'npub, nsec or hex';
			case 'useAmber': return 'Use Amber';
			case 'setValidKey': return 'Set a valid key';
			case 'pasteYourKey': return 'Paste your key';
			case 'taylorExperienceInterests': return 'Tailor your experience by selecting your top interests';
			case 'peopleCountPlus': return ({required Object number}) => '+${number} people';
			case 'followAll': return 'Follow all';
			case 'unfollowAll': return 'Unfollow all';
			case 'details': return 'details';
			case 'shareGlimps': return 'Share a glimpse of you, in words that feel true.';
			case 'addCover': return 'Add cover';
			case 'editCover': return 'Edit cover';
			case 'yourName': return 'Your name';
			case 'setProperName': return 'Set a proper name';
			case 'aboutYou': return 'About you';
			case 'secKeyDesc': return 'You can find your account secret key in your settings. This key is essential to secure access to your account. Please keep it safe and private.';
			case 'secKeyWalletDesc': return 'You can find your account secret key and wallet connection secret in your settings. These keys are essential to secure access to your account and wallet. Please keep them safe and private.';
			case 'initializingAccount': return 'Initializing account...';
			case 'letsGetStarted': return 'Let\'s get started!';
			case 'dontHaveWallet': return 'Don\'t have a wallet?';
			case 'createWalletSendRecSats': return 'Create a wallet to send and receive sats';
			case 'createWallet': return 'Create wallet';
			case 'youreAllSet': return 'You\'re all set';
			case 'dashboard': return 'dashboard';
			case 'verifyNotes': return 'Verify notes';
			case 'settings': return 'settings';
			case 'manageAccounts': return 'Manage accounts';
			case 'login': return 'Login';
			case 'switchAccounts': return 'Switch accounts';
			case 'addAccount': return 'Add account';
			case 'logoutAllAccounts': return 'Logout all accounts';
			case 'search': return 'search';
			case 'smartWidgets': return 'Smart widgets';
			case 'notifications': return 'notifications';
			case 'inbox': return 'inbox';
			case 'discover': return 'discover';
			case 'wallet': return 'wallet';
			case 'publicKey': return 'Public key';
			case 'profileLink': return 'Profile link';
			case 'profileCopied': return 'Profile link was copied! 👏';
			case 'publicKeyCopied': return 'Public key was copied! 👏';
			case 'lnCopied': return 'lightning address was copied! 👏';
			case 'scanQrCode': return 'Scan QR code';
			case 'viewQrCode': return 'View QR code';
			case 'copyNpub': return 'Copy pubkey';
			case 'visitProfile': return 'Visit profile';
			case 'followMeOnNostr': return 'Follow me on Nostr';
			case 'close': return 'close';
			case 'loadingPreviousPosts': return 'Loading previous post(s)...';
			case 'noRepliesDesc': return 'No replies for this note can be found';
			case 'thread': return 'thread';
			case 'all': return 'all';
			case 'mentions': return 'mentions';
			case 'zaps': return 'zaps';
			case 'noNotificationCanBeFound': return 'No notifications can be found';
			case 'consumablePointsPerks1': return '1- Submit your content for attestation';
			case 'consumablePointsPerks2': return '2- Redeem points to publish paid notes';
			case 'consumablePointsPerks3': return '3- Redeem points for SATs (Random thresholds are selected and you will be notified whenever redemption is available)';
			case 'yakihonneConsPoints': return 'YakiHonne\'s Consumable points';
			case 'soonUsers': return 'Soon users will be able to use the consumable points in the following set of activities:';
			case 'startEarningPoints': return 'Start earning and make the most of your Yaki Points! 🎉';
			case 'gotIt': return 'Got it!';
			case 'engagementChart': return 'Engagement chart';
			case 'lastGained': return ({required Object date}) => 'Last gained: ${date}';
			case 'attemptsRemained': return 'Attempts remained ';
			case 'congratulations': return 'Congratulations';
			case 'congratsDesc': return ({required Object number}) => 'You have been rewarded ${number} xp for the following actions, be active and earn rewards!';
			case 'yakihonneChest': return 'YakiHonne\'s Chest!';
			case 'noImGood': return 'No, I\'m good';
			case 'points': return 'Points';
			case 'unlocked': return 'Unlocked';
			case 'locked': return 'Locked';
			case 'whatsThis': return 'What\'s this?';
			case 'levelNumber': return ({required Object number}) => 'Level ${number}';
			case 'pointsSystem': return 'Points system';
			case 'oneTimeRewards': return 'One time rewards';
			case 'repeatedRewards': return 'Repeated rewards';
			case 'consumablePoints': return 'Consumable points';
			case 'pointsRemaining': return ({required Object number}) => '${number} remaining';
			case 'gain': return 'Gain';
			case 'forName': return ({required Object name}) => 'for ${name}';
			case 'min': return 'min';
			case 'levelsRequiredNum': return ({required Object number}) => '${number} levels required';
			case 'seeMore': return 'See more';
			case 'deleteCoverPic': return 'Delete cover picture!';
			case 'deleteCoverPicDesc': return 'You\'re about to delete your cover picture, do you wish to proceed?';
			case 'editProfile': return 'Edit profile';
			case 'uploadingImage': return 'Uploading image...';
			case 'updateProfile': return 'Update Profile';
			case 'userName': return 'User name';
			case 'displayName': return 'Display name';
			case 'yourDisplayName': return 'Your display name';
			case 'writeSomethingAboutYou': return 'Write something about you!';
			case 'website': return 'Website';
			case 'yourWebsite': return 'Your website';
			case 'verifyNip05': return 'Verified Nostr Address (NIP 05)';
			case 'enterNip05': return 'Enter your NIP-05 address';
			case 'enterLn': return 'Enter your address LUD-06 or LUD-16';
			case 'less': return 'Less';
			case 'more': return 'More';
			case 'pictureUrl': return 'Picture url';
			case 'coverUrl': return 'Cover url';
			case 'enterPictureUrl': return 'Enter your picture url';
			case 'enterCoverUrl': return 'Enter your cover url';
			case 'userNoArticles': return ({required Object name}) => '${name} has no articles';
			case 'userNoCurations': return ({required Object name}) => '${name} has no curations';
			case 'userNoNotes': return ({required Object name}) => '${name} has no notes';
			case 'userNoVideos': return ({required Object name}) => '${name} has no videos';
			case 'loadingFollowings': return 'Loading followings';
			case 'loadingFollowers': return 'loading followers';
			case 'followersNum': return ({required Object number}) => '${number} followers';
			case 'notFollowedByAnyoneYouFollow': return 'Not followed by anyone you follow.';
			case 'mutuals': return 'mutual(s)';
			case 'mutualsNum': return ({required Object number}) => '+ ${number} mutual(s)';
			case 'followsYou': return 'Follows you';
			case 'userNameCopied': return 'User name was successfully copied!';
			case 'profileRelays': return ({required Object number}) => 'Profile recommended relays - ${number}';
			case 'noUserRelays': return 'No relays for this user were found.';
			case 'userNoSmartWidgets': return ({required Object name}) => '${name} has no smart widgets';
			case 'un1': return 'Ratings of Not Helpful on notes that ended up with a status of Helpful';
			case 'un1Desc': return 'These ratings are counted twice because they often indicate support for notes that others deemed helpful.';
			case 'un2': return 'Notes with ongoing ratings';
			case 'un2Desc': return 'Ratings on notes that don\'t currently have a status of Helpful or Not Helpful';
			case 'unTextW1': return 'Notes that earned the status of Helpful';
			case 'unTextW1Desc': return 'These notes are now showing to everyone who sees the post, adding context and helping keep people informed.';
			case 'unTextR1': return 'Ratings that helped a note earn the status of Helpful';
			case 'unTextR1Desc': return 'These ratings identified Helpful notes that gets shown to everyone, adding context and helping keep people informed.';
			case 'unTextW2': return 'Notes that reached the status of Not Helpful';
			case 'unTextW2Desc': return 'These notes have been rated Not Helpful by enough contributors, including those who sometimes disagree in their past ratings.';
			case 'unTextR2': return 'Ratings that helped a note earn the status of Not Helpful';
			case 'unTextR2Desc': return 'These ratings improve Verified Notes by giving feedback to note authors, and allowing contributors to focus on the most promising notes';
			case 'unTextW3': return 'Notes that need more ratings';
			case 'unTextW3Desc': return 'Notes that don\'t yet have a status of Helpful or Not Helpful.';
			case 'unTextR3': return 'Ratings of Not Helpful on notes that ended up with a status of Helpful';
			case 'unTextR3Desc': return 'Don\'t worry, everyone gets some of these! These ratings are common and can lead to status changes if enough people agree that a \'Helpful\' note isn\'t sufficiently helpful.';
			case 'refresh': return 'refresh';
			case 'userImpact': return 'User\'s impact';
			case 'userRelays': return 'User\'s relays';
			case 'rewards': return 'rewards';
			case 'noRewards': return 'You have no rewards, interact with or write verified notes in order to obtain them.';
			case 'onDate': return ({required Object date}) => 'On ${date}';
			case 'youHaveRated': return 'You have rated';
			case 'theFollowingNote': return 'the following note:';
			case 'youHaveLeftNote': return 'You have left a note on this paid note:';
			case 'paidNoteLoading': return 'Paid note loading';
			case 'yourNoteSealed': return 'Your following note just got sealed:';
			case 'ratedNoteSealed': return 'You have rated the following note which got sealed:';
			case 'claimTime': return ({required Object time}) => 'Claim in ${time}';
			case 'claim': return 'Claim';
			case 'requestInProgress': return 'Request in progress';
			case 'granted': return 'Granted';
			case 'interested': return 'Interested';
			case 'notInterested': return 'Not interested';
			case 'noResKeyword': return 'No result for this keyword';
			case 'noResKeywordDesc': return 'No results have been found using this keyword, try to use another keywords in order to get a better results.';
			case 'startSearchPeople': return 'Start searching for people';
			case 'startSearchContent': return 'Start searching for content';
			case 'keys': return 'Keys';
			case 'myPublicKey': return 'My public key';
			case 'mySecretKey': return 'My secret key';
			case 'show': return 'show';
			case 'showSecret': return 'Show secret key!';
			case 'showSecretDesc': return 'Make sure to keep it safe as it gives a full access to your account.';
			case 'usingExternalSign': return 'Using an external signer';
			case 'usingExternalSignDesc': return 'You are using an external signer';
			case 'privKeyCopied': return 'Private key was copied! 👏';
			case 'muteList': return 'Mute list';
			case 'noMutedUserFound': return 'No muted users have been found.';
			case 'searchRelay': return 'Search relay';
			case 'deleteAccount': return 'Delete account';
			case 'clearAppCache': return 'Clear app cache';
			case 'clearAppCacheDesc': return 'You are about to clear the app cache, do you wish to proceed?';
			case 'clear': return 'clear';
			case 'fontSize': return 'Font Size';
			case 'appTheme': return 'App theme';
			case 'contentModeration': return 'Content moderation';
			case 'mediaUploader': return 'Media uploader';
			case 'secureDirectMessaging': return 'Secure direct messaging';
			case 'customization': return 'Customization';
			case 'hfCustomization': return 'Home feed customization';
			case 'newPostGesture': return 'New post long press gesture';
			case 'profilePreview': return 'Profile preview';
			case 'relaySettings': return ({required Object number}) => 'Relay settings ${number}';
			case 'yakihonne': return 'YakiHonne';
			case 'wallets': return 'wallets';
			case 'addWallet': return 'Add wallet';
			case 'externalWallet': return 'External wallet';
			case 'yakiChest': return 'Yaki chest';
			case 'connected': return 'Connected';
			case 'connect': return 'Connect';
			case 'owner': return 'Owner';
			case 'contact': return 'Contact';
			case 'software': return 'Software';
			case 'version': return 'Version';
			case 'supportedNips': return 'Supported Nips';
			case 'instantConntect': return 'Instant connect to relay';
			case 'invalidRelayUrl': return 'Invalid relay url';
			case 'relays': return 'Relays';
			case 'readOnly': return 'Read only';
			case 'writeOnly': return 'Write only';
			case 'readWrite': return 'Read/Write';
			case 'defaultKey': return 'Default';
			case 'viewProfile': return 'View profile';
			case 'appearance': return 'Appearance';
			case 'untitled': return 'Untitled';
			case 'smartWidgetChecker': return 'Smart widget checker';
			case 'naddr': return 'naddr';
			case 'noComponentsDisplayed': return 'No components can be displayed';
			case 'metadata': return 'metadata';
			case 'createdAt': return 'Created at';
			case 'identifier': return 'Identifier';
			case 'enterSMaddr': return 'Enter a smart widget naddr to check for its validity.';
			case 'notFindSMwithAddr': return 'Could not find smart widget with such address';
			case 'unableToOpenUrl': return 'Unable to open url';
			case 'voteToSeeStats': return 'You should vote to be able to see stats';
			case 'votesByZaps': return 'Votes by zaps';
			case 'votesByUsers': return 'Votes by users';
			case 'alreadyVoted': return 'You have already voted on this poll';
			case 'userCannotBeFound': return 'User cannot be found';
			case 'votesNumber': return ({required Object number}) => 'Votes: ${number}';
			case 'voteRequired': return 'Vote is required to display stats.';
			case 'showStats': return 'Show stats';
			case 'pollClosesAt': return ({required Object date}) => 'Closes at: ${date}';
			case 'pollClosedAt': return ({required Object date}) => 'Closed at: ${date}';
			case 'checkSmartWidget': return 'Check a smart widget';
			case 'emptyVerifiedNote': return 'Empty verified note content!';
			case 'post': return 'Post';
			case 'seeAnything': return 'See anything you want to improve?';
			case 'writeNote': return 'Write a note';
			case 'whatThinkThis': return 'What do you think about this ?';
			case 'sourceRecommended': return 'Source (recommended)';
			case 'findPaidNoteCorrect': return 'You find this paid note correct.';
			case 'findPaidNoteMisleading': return 'You find this paid note misleading.';
			case 'selectOneReason': return 'Select at least one reason';
			case 'rateHelpful': return 'Rate helpful';
			case 'rateNotHelpful': return 'Rate not helpful';
			case 'ratedHelpful': return 'Rated helpful';
			case 'ratedNotHelpful': return 'Rated not helpful';
			case 'youRatedHelpful': return 'you rated this as helpful';
			case 'youRatedNotHelpful': return 'you rated this as not helpful';
			case 'findThisHelpful': return 'Do you find this helpful?';
			case 'findThisNotHelpful': return 'Do you find this not helpful?';
			case 'setYourRating': return 'Set your rating';
			case 'whatThinkOfThat': return 'What do you think of that?';
			case 'changeRatingNote': return 'Note: changing your rating will only be valid for 5 minutes, after that you will no longer have the option to undo or change it.';
			case 'paidNote': return 'Paid note';
			case 'undo': return 'Undo';
			case 'undoRating': return 'Undo rating';
			case 'undoRatingDesc': return 'You are about to undo your rating, do you wish to proceed?';
			case 'seeAllAttempts': return 'See all attempts';
			case 'addNote': return 'Add note';
			case 'alreadyContributed': return 'You have already contributed';
			case 'notesFromCommunity': return 'Notes from the community';
			case 'noCommunityNotes': return 'It\'s quiet here! No community notes yet.';
			case 'notHelpful': return 'Not helpful';
			case 'sealed': return 'Sealed';
			case 'notSealed': return 'Not sealed';
			case 'notSealedYet': return 'Not sealed yet';
			case 'needsMoreRating': return 'Needs more rating';
			case 'source': return 'Source';
			case 'thisNoteAwaitRating': return 'this note is awaiting community rating.';
			case 'yourNoteAwaitRating': return 'this note is awaiting community rating.';
			case 'topReasonsSelected': return 'Top reasons selected by raters:';
			case 'noReasonsSpecified': return 'No reasons are specified!';
			case 'postedOn': return ({required Object date}) => 'Posted on ${date}';
			case 'explanation': return 'Explanation';
			case 'readAboutVerifyingNotes': return 'Read about verifying notes';
			case 'readAboutVerifyingNotesDesc': return 'We\'ve made an article for you to help you understand our purpose';
			case 'readArticle': return 'Read article';
			case 'whyVerifyingNotes': return 'Why the verifying notes?';
			case 'contributeUnderstanding': return 'Contribute to build understanding';
			case 'actGoodFaith': return 'Act in good faith';
			case 'beHelpful': return 'Be helpful, even to those who disagree';
			case 'readMore': return 'Read more';
			case 'newKey': return 'New';
			case 'needsYourHelp': return 'Needs your helpful';
			case 'communityWallet': return 'Community wallet';
			case 'noPaidNotesCanBeFound': return 'No paid notes can be found.';
			case 'updatesNews': return 'Updates news';
			case 'updates': return 'Updates';
			case 'toBeAbleSendSats': return 'To be able to send zaps, please make sure to connect your bitcoin lightning wallet.';
			case 'receiveSats': return 'Receive sats';
			case 'messageOptional': return 'Message (optional)';
			case 'amountInSats': return 'Amount in sats';
			case 'invoiceCopied': return 'Invoice code copied!';
			case 'copyInvoice': return 'Copy invoice';
			case 'ensureLnSet': return 'Ensure that your lightning address is well set';
			case 'errorGeneratingInvoice': return 'Error occured while generating invoice';
			case 'generateInvoice': return 'Generate invoice';
			case 'qrCode': return 'QR code';
			case 'scanPay': return 'Scan & pay';
			case 'slideToPay': return 'Slide to pay';
			case 'invalidInvoice': return 'Invalid invoice';
			case 'invalidInvoiceDesc': return 'It seems that the scanned invoice is invalid, re-scan and try again.';
			case 'scanAgain': return 'Scan again';
			case 'sendSats': return 'Send sats';
			case 'send': return 'Send';
			case 'recentTransactions': return 'Recent transactions';
			case 'noTransactionCanBeFound': return 'No transactions can be found';
			case 'selectWalletTransactions': return 'Select a wallet to obtain latest transactions.';
			case 'noUserCanBeFound': return 'No users can be found.';
			case 'balance': return 'Balance';
			case 'noLnInNwc': return 'We could not retrieve your address from your NWC secret, kindly check your lightning address service provider to copy your address or to update your profile accordinaly.';
			case 'copyLn': return 'Copy lightning address';
			case 'receive': return 'Receive';
			case 'clickBelowToConnect': return 'Click below to connect';
			case 'connectWithNwc': return 'Connect with NWC';
			case 'pasteNwcAddress': return 'Paste NWC address';
			case 'createYakiWallet': return 'Create YakiHonne\'s wallet';
			case 'yakiNwc': return 'YakiHonne\'s NWC';
			case 'yakiNwcDesc': return 'Create wallet using YakiHonne\'s channel';
			case 'orUseYourWallet': return 'Or use your wallet';
			case 'nostrWalletConnect': return 'Nostr wallet connect';
			case 'nostrWalletConnectDesc': return 'Native nostr wallet connection';
			case 'alby': return 'Alby';
			case 'albyConnect': return 'Alby connect';
			case 'walletDataNote': return 'Note: All the data related to your wallet will be safely and securely stored locally and are never shared outside the confines of the application.';
			case 'availableWallets': return 'Available wallets';
			case 'noWalletLinkedToYouProfile': return 'You have no wallet linked to your profile.';
			case 'noWalletConnectedToYourProfile': return 'None of the connected wallets are linked to your profile.';
			case 'click': return 'Click';
			case 'onSelectedWalletLinkIt': return 'on your selected wallet & link it.';
			case 'noWalletCanBeFound': return 'No wallet can be found';
			case 'currentlyLinkedMessage': return 'Currently linked with your profile for zaps receiving';
			case 'linked': return 'Linked';
			case 'linkWallet': return 'Link wallet';
			case 'linkWalletDesc': return 'You are about to override your previous wallet and link a new one to your profile, do you wish to proceed?';
			case 'copyNwc': return 'Copy NWC';
			case 'nwcCopied': return 'NWC has been successfuly copied!';
			case 'deleteWallet': return 'Delete wallet';
			case 'deleteWalletDesc': return 'You are about to delete this wallet, do you wish to proceed?';
			case 'userSentSat': return ({required Object name, required Object number}) => '${name} sent you ${number} Sats';
			case 'userReceivedSat': return ({required Object name, required Object number}) => '${name} received from you ${number} Sats';
			case 'ownSentSat': return ({required Object number}) => 'You sent ${number} Sats';
			case 'ownReceivedSat': return ({required Object number}) => 'You received ${number} Sats';
			case 'comment': return 'Comment';
			case 'supportYakihonne': return 'Support YakiHonne';
			case 'fuelYakihonne': return 'Fuel YakiHonne\'s growth! Your support drives new features and a better experience for everyone.';
			case 'supportUs': return '❤︎ Support us';
			case 'peopleToFollow': return 'People to follow';
			case 'donations': return 'Donations';
			case 'inTag': return ({required Object name}) => 'In ${name}';
			case 'shareProfile': return 'Share profile';
			case 'shareProfileDesc': return 'Share your profile to reach more people, connect with others, and grow your network';
			case 'moreDots': return 'more...';
			case 'comments': return 'Comments';
			case 'noCommentsCanBeFound': return 'No comments can be found';
			case 'beFirstCommentThisVideo': return 'Be the first to comment on this video !';
			case 'errorLoadingVideo': return 'Error while loading the video';
			case 'seeAlso': return 'See also';
			case 'viewsNumber': return ({required Object number}) => '${number} view';
			case 'upvotes': return 'Upvotes';
			case 'downvotes': return 'Downvotes';
			case 'views': return 'Views';
			case 'createdAtEditedAt': return ({required Object date1, required Object date2}) => 'created at ${date1}, edited on ${date2}';
			case 'loading': return 'Loading';
			case 'releaseToLoad': return 'Release to load more';
			case 'finished': return 'finished!';
			case 'noMoreData': return 'No more data';
			case 'refreshed': return 'Refreshed';
			case 'refreshing': return 'Refreshing';
			case 'pullToRefresh': return 'Pull to refresh';
			case 'suggestedInterests': return 'Suggested interests';
			case 'reveal': return 'Reveal';
			case 'wantToShareRevenues': return 'I want to share this revenues';
			case 'splitRevenuesWithUsers': return 'Split revenues with users';
			case 'addUser': return 'Add user';
			case 'selectAdate': return 'Select a date';
			case 'clearDate': return 'Clear date';
			case 'nothingToShowHere': return 'Oops! Nothing to show here!';
			case 'confirmPayment': return 'Confirm payment';
			case 'payWithNwc': return 'Pay with NWC';
			case 'important': return 'Important';
			case 'adjustVolume': return 'Adjust volume';
			case 'adjustSpeed': return 'Adjust speed';
			case 'updateInterests': return 'Update interests';
			case 'usingViewMode': return 'You\'re using view mode';
			case 'usingViewModeDesc': return 'Sign in with your private key and join the community.';
			case 'noInternetAccess': return 'No internetAccess';
			case 'checkModelRouter': return 'Check your modem or router';
			case 'reconnectWifi': return 'Reconnect to a wifi';
			case 'somethingWentWrong': return 'Something went wrong !';
			case 'somethingWentWrongDesc': return 'It looks like something happened while loading the data, try again!';
			case 'tryAgain': return 'Try again';
			case 'postNotFound': return 'Post could not be found';
			case 'user': return 'user';
			case 'view': return 'view';
			case 'itsLive': return 'It\'s live!';
			case 'spreadWordSharingContent': return 'Spread the word by sharing your content everywhere.';
			case 'successfulRelays': return 'Successful relays';
			case 'noRelaysCanBeFound': return 'No relays can be found';
			case 'dismiss': return 'dismiss';
			case 'deleteAccountMessage': return 'You are attempting to login to a deleted account.';
			case 'exit': return 'Exit';
			case 'shareContent': return 'Share content';
			case 'profile': return 'Profile';
			case 'by': return 'by';
			case 'shareLink': return 'Share link';
			case 'shareImage': return 'Share image';
			case 'shareNoteId': return 'Share note id';
			case 'shareNprofile': return 'Share nprofile';
			case 'shareNaddr': return 'Share naddr';
			case 'bio': return ({required Object content}) => 'Bio: ${content}';
			case 'earnSats': return 'Earn SATs';
			case 'earnSatsDesc': return 'Help us provide more decentralized insights to review this paid note.';
			case 'verifyingNote': return 'Verifying note';
			case 'pickYourImage': return 'Pick your image';
			case 'uploadPasteUrl': return 'You can upload or paste a url for your preffered image';
			case 'back': return 'back';
			case 'camera': return 'Camera';
			case 'communityWidgets': return 'Community widgets';
			case 'myWidgets': return 'My widgets';
			case 'pendingUnfollowing': return 'Unfollowing...';
			case 'pendingFollowing': return 'Following...';
			case 'zappers': return 'Zappers';
			case 'noZappersCanBeFound': return 'No zappers can be found.';
			case 'payPublish': return 'Pay & Publish';
			case 'payPublishNote': return 'Note: Ensure that all the content that you provided is final since the publishing is deemed irreversible & the spent SATS are non refundable.';
			case 'userSubmittedPaidNote': return ({required Object name}) => '${name} has submitted a paid note';
			case 'getInvoice': return 'Get invoice';
			case 'pay': return 'Pay';
			case 'compose': return 'Compose';
			case 'writeSomething': return 'Write something...';
			case 'highlightedNote': return 'A highlighted note for more exposure.';
			case 'typeValidZapQuestion': return 'Type a valid poll question!';
			case 'pollOptions': return 'Poll options';
			case 'minimumSatoshis': return 'Minimum satoshis';
			case 'minSats': return 'Min sats';
			case 'maxSats': return 'Max sats';
			case 'maximumSatoshis': return 'Maximum satoshis';
			case 'pollCloseDate': return 'Poll close date';
			case 'optionsNumber': return ({required Object number}) => 'Options: ${number}';
			case 'zapSplits': return 'Zap splits';
			case 'minimumOfOneRequired': return 'A minimum amount of 1 is required';
			case 'valueBetweenMinMax': return 'The value should be between the min and max sats amount';
			case 'writeCommentOptional': return 'Write a comment (optional)';
			case 'splitZapsWith': return 'Split zaps with';
			case 'useCannotBeZapped': return 'This user cannot be zapped';
			case 'waitingGenerationOfInvoice': return 'Waiting for the generation of invoices.';
			case 'userInvoiceGenerated': return ({required Object name}) => 'An invoice for ${name} has been generated';
			case 'userInvoiceNotGenerated': return 'Could not create an invoice for this user.';
			case 'payAmount': return ({required Object number}) => 'Pay ${number} sats';
			case 'generateInvoices': return 'Generate invoices';
			case 'userZappedSuccesfuly': return 'User was zapped successfuly';
			case 'useValidTitle': return 'A valid title needs to be used';
			case 'errorAddingBookmark': return 'Error occured when adding the bookmark';
			case 'bookmarkAdded': return 'Bookmark list has been added';
			case 'voteNotSubmitted': return 'Vote could not be submitted';
			case 'zapSplitsMessage': return 'For zap splits, there should be at least one person';
			case 'errorUpdatingCuration': return 'An error occured while updating the curation';
			case 'errorAddingCuration': return 'An error occured while adding the curation';
			case 'errorDeletingContent': return 'Error occured while deleting content';
			case 'errorSigningEvent': return 'Error occured while signing the event';
			case 'errorSendingEvent': return 'Error occured while sending the event';
			case 'errorSendingMessage': return 'error occured while sending the message';
			case 'userHasBeenMuted': return 'User has been muted';
			case 'userHasBeenUnmuted': return 'User has been unmuted';
			case 'messageCouldNotBeDecrypted': return 'message could not be decrypted';
			case 'interestsUpdateMessage': return 'Interest list has been updated successfuly!';
			case 'errorGeneratingEvent': return 'Error occured while generating event';
			case 'oneFeedOptionAvailable': return 'There should be at least one feed option available.';
			case 'walletCreated': return 'Wallet has been created successfuly';
			case 'walletLinked': return 'Wallet has been linked successfuly';
			case 'errorCreatingWallet': return 'Error occured while creating wallet';
			case 'walletNotLinked': return 'Wallet cannot be linked. Wrong lighting address';
			case 'invalidPairingSecret': return 'Invalid pairing secret';
			case 'errorSettingToken': return 'Error occured while setting up the token';
			case 'nwcInitialized': return 'Nostr wallet connect has been initialized';
			case 'noWalletLinkedMessage': return 'You have no wallet linked to your profile, do you wish to link this wallet?';
			case 'errorUsingWallet': return 'Error occured while using wallet!';
			case 'submitValidData': return 'Make sure you submit a valid data';
			case 'submitValidInvoice': return 'Make sure you submit a valid invoice';
			case 'paymentSucceeded': return 'Payment succeeded';
			case 'paymentFailed': return 'Payment failed';
			case 'notEnoughBalance': return 'Not enough balance to make this payment.';
			case 'permissionInvoiceNotGranted': return 'Permission to pay invoices is not granted.';
			case 'allUsersZapped': return 'All the users have been zapped!';
			case 'partialUsersZapped': return 'Partial users are zapped!';
			case 'noUserZapped': return 'No user has been zapped!';
			case 'errorZappingUsers': return 'Error occured while zapping users';
			case 'selectDefaultWallet': return 'Select a default wallet in the settings.';
			case 'noInvoiceAvailable': return 'No invoices are available';
			case 'invoicePaid': return 'Invoice has been paid successfuly';
			case 'errorPayingInvoice': return 'Error occured while paying using invoice';
			case 'errorUsingExternalWallet': return 'Error while using external wallet.';
			case 'paymentSurpassMax': return 'Payment Surpasses the maximum amount allowed.';
			case 'errorSendingSats': return 'Error occured while sending sats';
			case 'setSatsMoreThanZero': return 'Set a sats amount greater than 0';
			case 'processCompleted': return 'Process has been completed';
			case 'relayingStuff': return 'Relaying stuff...';
			case 'amberNotInstalled': return 'Amber app is not installed';
			case 'alreadyLoggedIn': return 'You are already logged in!';
			case 'loggedIn': return 'You are logged in!';
			case 'attemptConnectAmber': return 'Attempt to connect with Amber has been rejected.';
			case 'errorUploadingImage': return 'Error ocurred while uploading image';
			case 'invalidPrivateKey': return 'Invalid private key!';
			case 'invalidHexKey': return 'Invalid hex key!';
			case 'fetchingArticle': return 'Fetching article';
			case 'articleNotFound': return 'Article could not be found';
			case 'fetchingCuration': return 'Fetching curation';
			case 'curationNotFound': return 'Curation could not be found';
			case 'fetchingSmartWidget': return 'Fetching smart widget';
			case 'smartWidgetNotFound': return 'Smart widget could not be found';
			case 'fetchingVideo': return 'Fetching video';
			case 'videoNotFound': return 'Video could not be found';
			case 'fetchingNote': return 'Fetching note';
			case 'noteNotFound': return 'Note could not be found';
			case 'eventNotFound': return 'Event could not be found';
			case 'verifiedNoteNotFound': return 'Verified note could not be found';
			case 'eventNotRecognized': return 'Event could not be recognized';
			case 'fetchingEventUserRelays': return 'Fetching event from user\'s relays';
			case 'fetchingProfile': return 'Fetching profile';
			case 'fetchingEvent': return 'Fetching event';
			case 'loggedToYakiChest': return 'You are logged in to Yakihonne\'s chest';
			case 'errorLoggingYakiChest': return 'Error occured while logging in to Yakihonne\'s chest';
			case 'relayInUse': return 'Relay already in use';
			case 'errorConnectingRelay': return 'Error occured while connecting to relay';
			case 'submitValidLud': return 'Make sure to get a valid lud16/lud06.';
			case 'errorUpdatingData': return 'Error occured while updating data';
			case 'updatedSuccesfuly': return 'Updated successfuly';
			case 'relaysListUpdated': return 'Relays list has been updated';
			case 'couldNotUpdateRelaysList': return 'Could not update relays list';
			case 'errorUpdatingRelaysList': return 'Error occured while updating relays list';
			case 'errorClaimingReward': return 'Error occured while claimaing a reward';
			case 'errorDecodingData': return 'Error occured while decoding data';
			case 'loggingIn': return 'Logging in...';
			case 'loggingOut': return 'Logging out...';
			case 'disconnecting': return 'Disconnecting...';
			case 'ratingSubmittedCheckReward': return 'Your rating has been submitted, check your rewards page to claim your rating reward';
			case 'errorSubmittingRating': return 'Error occured while submitting your rating';
			case 'verifiedNoteAdded': return 'Your verified note has been added, check your rewards page to claim your writing reward';
			case 'errorAddingVerifiedNote': return 'Error occured while adding your verified note';
			case 'ratingDeleted': return 'Your rating has been deleted';
			case 'errorDeletingRating': return 'Error occured while deleting your rating';
			case 'autoSavedArticleDeleted': return 'Auto-saved article has been deleted';
			case 'articlePublished': return 'Your article has been published!';
			case 'errorAddingArticle': return 'An error occured while adding the article';
			case 'writeValidNote': return 'Write down a valid note!';
			case 'setOutboxRelays': return 'Make sure to set up your outbox relays';
			case 'notePublished': return 'Note has been published!';
			case 'paidNotePublished': return 'Paid note has been published!';
			case 'invoiceNotPayed': return 'It seemse that you didn\'t pay the invoice, recheck again';
			case 'autoSavedSMdeleted': return 'Auto-saved smart widget has been deleted';
			case 'errorUploadingMedia': return 'Error occured while uploading the media';
			case 'smartWidgetPublishedSuccessfuly': return 'Smart widget has been published successfuly';
			case 'errorAddingWidget': return 'An error occured while adding the smart widget';
			case 'setAllRequiredContent': return 'Make sure to set all the required content.';
			case 'noEventIdCanBeFound': return 'No event with this id can be found!';
			case 'notValidVideoEvent': return 'This event is not a valid video event!';
			case 'emptyVideoUrl': return 'This nevent has an empty url';
			case 'submitValidVideoEvent': return 'Please submit a valid video event';
			case 'errorUploadingVideo': return 'Error occured while uploading the video';
			case 'errorAddingVideo': return 'An error occured while adding the video';
			case 'submitMinMaxSats': return 'Make sure to submit valid minimum & maximum satoshis';
			case 'submitValidCloseDate': return 'Make sure to submit valid close date.';
			case 'submitValidOptions': return 'Make sure to submit valid options.';
			case 'pollZapPublished': return 'Poll zap has been published!';
			case 'relaysNotReached': return 'Relays could not be reached';
			case 'loginYakiChestPoints': return 'Login to Yakihonne\'s chest, accumulate points by being active on the platform and win precious awards!';
			case 'inaccessibleLink': return 'Inaccessible link';
			case 'mediaExceedsMaxSize': return 'Media exceeds the maximum size which is 21 mb';
			case 'fetchingUserInboxRelays': return 'Fetching user inbox relays';
			case 'userZappedYou': return ({required Object name, required Object number}) => '${name} zapped you ${number} sats';
			case 'userReactedYou': return ({required Object name, required Object reaction}) => '${name} reacted ${reaction} to you';
			case 'userRepostedYou': return ({required Object name}) => '${name} reposted your content';
			case 'userMentionedYouInComment': return ({required Object name}) => '${name} mentioned you in a comment';
			case 'userMentionedYouInNote': return ({required Object name}) => '${name} mentioned you in a note';
			case 'userMentionedYouInPaidNote': return ({required Object name}) => '${name} mentioned you in a paid note';
			case 'userMentionedYouInArticle': return ({required Object name}) => '${name} mentioned you in an article';
			case 'userMentionedYouInVideo': return ({required Object name}) => '${name} mentioned you in a video';
			case 'userMentionedYouInCuration': return ({required Object name}) => '${name} mentioned you in a curation';
			case 'userMentionedYouInSmartWidget': return ({required Object name}) => '${name} mentioned you in a smart widget';
			case 'userMentionedYouInPoll': return ({required Object name}) => '${name} mentioned you in a poll';
			case 'userPublishedPaidNote': return ({required Object name}) => '${name} published a paid note';
			case 'userPublishedArticle': return ({required Object name}) => '${name} published an article';
			case 'userPublishedVideo': return ({required Object name}) => '${name} published a video';
			case 'userPublishedCuration': return ({required Object name}) => '${name} published a curation';
			case 'userPublishedSmartWidget': return ({required Object name}) => '${name} published a smart widget';
			case 'userPublishedPoll': return ({required Object name}) => '${name} published a poll';
			case 'userZappedYourArticle': return ({required Object name, required Object number}) => '${name} zapped your article ${number} sats';
			case 'userZappedYourCuration': return ({required Object name, required Object number}) => '${name} zapped your curation ${number} sats';
			case 'userZappedYourVideo': return ({required Object name, required Object number}) => '${name} zapped your video ${number} sats';
			case 'userZappedYourSmartWidget': return ({required Object name, required Object number}) => '${name} zapped your smart widget ${number} sats';
			case 'userZappedYourPoll': return ({required Object name, required Object number}) => '${name} zapped your poll ${number} sats';
			case 'userZappedYourNote': return ({required Object name, required Object number}) => '${name} zapped your note ${number} sats';
			case 'userZappedYourPaidNote': return ({required Object name, required Object number}) => '${name} zapped your paid note ${number} sats';
			case 'userReactedYourArticle': return ({required Object name, required Object reaction}) => '${name} reacted ${reaction} to your article';
			case 'userReactedYourCuration': return ({required Object name, required Object reaction}) => '${name} reacted ${reaction} to your curation';
			case 'userReactedYourVideo': return ({required Object name, required Object reaction}) => '${name} reacted ${reaction} to your video';
			case 'userReactedYourSmartWidget': return ({required Object name, required Object reaction}) => '${name} reacted ${reaction} to your smart widget';
			case 'userReactedYourPoll': return ({required Object name, required Object reaction}) => '${name} reacted ${reaction} to your poll';
			case 'userReactedYourNote': return ({required Object name, required Object reaction}) => '${name} reacted ${reaction} to your note';
			case 'userReactedYourPaidNote': return ({required Object name, required Object reaction}) => '${name} reacted ${reaction} to your paid note';
			case 'userReactedYourMessage': return ({required Object name, required Object reaction}) => '${name} reacted ${reaction} to your message';
			case 'userRepostedYourNote': return ({required Object name}) => '${name} reposted your note';
			case 'userRepostedYourPaidNote': return ({required Object name}) => '${name} reposted your paid note';
			case 'userRepliedYourArticle': return ({required Object name}) => '${name} replied to your article';
			case 'userRepliedYourCuration': return ({required Object name}) => '${name} replied to your curation';
			case 'userRepliedYourVideo': return ({required Object name}) => '${name} replied to your video';
			case 'userRepliedYourSmartWidget': return ({required Object name}) => '${name} replied to your smart widget';
			case 'userRepliedYourPoll': return ({required Object name}) => '${name} replied to your poll';
			case 'userRepliedYourNote': return ({required Object name}) => '${name} replied to your note';
			case 'userRepliedYourPaidNote': return ({required Object name}) => '${name} replied to your paid note';
			case 'userCommentedYourArticle': return ({required Object name}) => '${name} commented on your article';
			case 'userCommentedYourCuration': return ({required Object name}) => '${name} commented on your curation';
			case 'userCommentedYourVideo': return ({required Object name}) => '${name} commented on your video';
			case 'userCommentedYourSmartWidget': return ({required Object name}) => '${name} commented on your smart widget';
			case 'userCommentedYourPoll': return ({required Object name}) => '${name} commented on your poll';
			case 'userCommentedYourNote': return ({required Object name}) => '${name} commented on your note';
			case 'userCommentedYourPaidNote': return ({required Object name}) => '${name} commented on your paid note';
			case 'userQuotedYourArticle': return ({required Object name}) => '${name} quoted your article';
			case 'userQuotedYourCuration': return ({required Object name}) => '${name} quoted your curation';
			case 'userQuotedYourVideo': return ({required Object name}) => '${name} quoted your video';
			case 'userQuotedYourNote': return ({required Object name}) => '${name} quoted your note';
			case 'userQuotedYourPaidNote': return ({required Object name}) => '${name} quoted your paid note';
			case 'userReactedArticleYouIn': return ({required Object name, required Object reaction}) => '${name} reacted ${reaction} to an article you were mentioned in';
			case 'userReactedCurationYouIn': return ({required Object name, required Object reaction}) => '${name} reacted ${reaction} to a curation you were mentioned in';
			case 'userReactedVideoYouIn': return ({required Object name, required Object reaction}) => '${name} reacted ${reaction} to a video you were mentioned in';
			case 'userReactedSmartWidgetYouIn': return ({required Object name, required Object reaction}) => '${name} reacted ${reaction} to a smart widget you were mentioned in';
			case 'userReactedPollYouIn': return ({required Object name, required Object reaction}) => '${name} reacted ${reaction} to a poll you were mentioned in';
			case 'userReactedNoteYouIn': return ({required Object name, required Object reaction}) => '${name} reacted ${reaction} to a note you were mentioned in';
			case 'userReactedPaidNoteYouIn': return ({required Object name, required Object reaction}) => '${name} reacted ${reaction} to a paid note you were mentioned in';
			case 'userRepostedNoteYouIn': return ({required Object name}) => '${name} reposted a note you were mentioned in';
			case 'userRepostedPaidNoteYouIn': return ({required Object name}) => '${name} reposted a paid note you were mentioned in';
			case 'userRepliedArticleYouIn': return ({required Object name}) => '${name} replied to a article you were mentioned in';
			case 'userRepliedCurationYouIn': return ({required Object name}) => '${name} replied to a curation you were mentioned in';
			case 'userRepliedVideoYouIn': return ({required Object name}) => '${name} replied to a video you were mentioned in';
			case 'userRepliedSmartWidgetYouIn': return ({required Object name}) => '${name} replied to a smart widget you were mentioned in';
			case 'userRepliedPollYouIn': return ({required Object name}) => '${name} replied to a poll you were mentioned in';
			case 'userRepliedNoteYouIn': return ({required Object name}) => '${name} replied to a note you were mentioned in';
			case 'userRepliedPaidNoteYouIn': return ({required Object name}) => '${name} replied to a paid note you were mentioned in';
			case 'userCommentedArticleYouIn': return ({required Object name}) => '${name} commented on an article you were mentioned in';
			case 'userCommentedCurationYouIn': return ({required Object name}) => '${name} commented on a curation you were mentioned in';
			case 'userCommentedVideoYouIn': return ({required Object name}) => '${name} commented on a video you were mentioned in';
			case 'userCommentedSmartWidgetYouIn': return ({required Object name}) => '${name} commented on a smart you were mentioned in widget';
			case 'userCommentedPollYouIn': return ({required Object name}) => '${name} commented on a poll you were mentioned in';
			case 'userCommentedNoteYouIn': return ({required Object name}) => '${name} commented on a note you were mentioned in';
			case 'userCommentedPaidNoteYouIn': return ({required Object name}) => '${name} commented on a paid you were mentioned in note';
			case 'userQuotedArticleYouIn': return ({required Object name}) => '${name} quoted an article you were mentioned in';
			case 'userQuotedCurationYouIn': return ({required Object name}) => '${name} quoted a curation you were mentioned in';
			case 'userQuotedVideoYouIn': return ({required Object name}) => '${name} quoted a video you were mentioned in';
			case 'userQuotedNoteYouIn': return ({required Object name}) => '${name} quoted a note you were mentioned in';
			case 'userQuotedPaidNoteYouIn': return ({required Object name}) => '${name} quoted a paid note you were mentioned in';
			case 'reactedWith': return ({required Object name, required Object reaction}) => '${name} reacted with ${reaction}';
			case 'verifiedNoteSealed': return 'Your verified note has been sealed.';
			case 'verifiedNoteRateSealed': return 'An verified note you have rated has been sealed.';
			case 'userNewVideo': return ({required Object name}) => '${name}\'s video';
			case 'titleData': return ({required Object description}) => 'Title: ${description}';
			case 'checkoutVideo': return 'checkout my video';
			case 'yakihonneNotification': return 'YakiHonne\'s notification';
			case 'unknownVerifiedNote': return 'Unknown\'s verified note';
			case 'userReply': return ({required Object name}) => '${name}\'s replied';
			case 'userPaidNote': return ({required Object name}) => '${name}\'s new paid note';
			case 'contentData': return ({required Object description}) => 'Content: ${description}';
			case 'checkoutPaidNote': return 'check out my paid note';
			case 'userNewCuration': return ({required Object name}) => '${name}\'s new curation';
			case 'userNewArticle': return ({required Object name}) => '${name}\'s new article';
			case 'userNewSmartWidget': return ({required Object name}) => '${name}\'s new smart widget';
			case 'checkoutArticle': return 'check out my article';
			case 'checkoutCuration': return 'check out my curation';
			case 'checkoutSmartWidget': return 'check out my smart widget';
			case 'languagePreferences': return 'Language preferences';
			case 'contentTranslation': return 'Content Translation';
			case 'appLanguage': return 'App language';
			case 'apiKeyRequired': return 'Api key (required)';
			case 'getApiKey': return 'Get API Key';
			case 'seeTranslation': return 'See translation';
			case 'seeOriginal': return 'See original';
			case 'plan': return 'Plan';
			case 'free': return 'Free';
			case 'pro': return 'Pro';
			case 'errorTranslating': return 'Error occured while translating content.';
			case 'errorMissingKey': return 'Missing API Key or expired subscription. Check Settings -> Language Preferences for more.';
			case 'comingSoon': return 'Coming soon';
			case 'content': return 'Content';
			case 'expiresOn': return ({required Object date}) => 'Expires on: ${date}';
			case 'collapseNote': return 'Collapse note';
			case 'reactions': return 'Reactions';
			case 'reposts': return 'Reposts';
			case 'notifDisabled': return 'Notifications are disabled!';
			case 'notifDisabledMessage': return 'Notifications are disabled for this type, you can enable it in the notifications settings.';
			case 'oneNotifOptionAvailable': return 'There should be at least one notification option available.';
			case 'readAll': return 'Read all';
			case 'usernameTaken': return 'Username is taken';
			case 'usernameRequired': return 'Username is required';
			case 'deleteWalletConfirmation': return 'Please ensure you securely save your NWC connection phrase, as we cannot assist with recovering lost wallets.';
			case 'unsupportedKind': return 'Unsupported kind';
			case 'analyticsCrashlytics': return 'Crashlytics';
			case 'analyticsCache': return 'Crashlytics & cache';
			case 'analyticsCacheOn': return 'Crashlytics have been turned on.';
			case 'analyticsCacheOff': return 'Crashlytics have been turned off.';
			case 'shareNoUsage': return 'You share no crashlytics with us at the moment.';
			case 'wantShareAnalytics': return 'Want to share crashlytics?';
			case 'yakihonneAnCr': return 'YakiHonne\'s crashlytics';
			case 'crashlyticsTerms': return 'Collecting anonymized crashlytics is vital for refining our app\'s features and user experience. It enables us to identify user preferences, enhance popular features, and make informed optimizations, ensuring a more personalized and efficient app for our users.';
			case 'collectAnonymised': return 'We collect anonymised crashlytics to improve the app experience.';
			case 'linkWalletToProfile': return 'Link wallet with your profile';
			case 'linkWalletToProfileDesc': return 'The linked wallet is going to be used to receive sats';
			case 'noWalletLinked': return 'You have no wallet linked to your profile consider linking one of yours in the menu above';
			case 'addPoll': return 'Add poll';
			case 'browsePolls': return 'Browse polls';
			case 'maciPolls': return 'MACI poll';
			case 'beta': return 'Beta';
			case 'choosePollType': return 'Choose a poll type';
			case 'created': return 'Created';
			case 'tallying': return 'Tallying';
			case 'ended': return 'Ended';
			case 'closed': return 'Closed';
			case 'voteResultsBy': return 'Vote results by';
			case 'votes': return 'votes';
			case 'voiceCredit': return 'Voice credit';
			case 'viewDetails': return 'View details';
			case 'signup': return 'Signup';
			case 'notDownloadProof': return 'Could not download proofs';
			case 'name': return 'Name';
			case 'status': return 'Status';
			case 'circuit': return 'Circuit';
			case 'votingSystem': return 'Voting system';
			case 'proofSystem': return 'Proof system';
			case 'gasStation': return 'Gas station';
			case 'totalFund': return '(total fund)';
			case 'roundStart': return 'Round start';
			case 'roundEnd': return 'Round end';
			case 'operator': return 'Operator';
			case 'contractCreator': return 'Contract creator';
			case 'contractAddress': return 'Contract address';
			case 'blockHeight': return 'Block height';
			case 'atContractCreation': return ({required Object number}) => '${number} (at contract creation)';
			case 'zkProofs': return 'ZK proofs';
			case 'downloadZkProofs': return 'Download proofs';
			case 'walletConnectionString': return 'Wallet Connection String';
			case 'walletConnectionStringDesc': return 'Please make sure to securely copy or export your wallet connection string. We do not store this information, and if lost, it cannot be recovered.';
			case 'export': return 'Export';
			case 'logout': return 'Log out';
			case 'exportAndLogout': return 'Export & log out';
			case 'exportWalletsDesc': return 'It looks like you have wallets linked to your account. Please download your wallet secrets before logging out.';
			case 'manageWallets': return 'Manage wallets';
			case 'roundDuration': return 'Round duration';
			case 'startAt': return ({required Object date}) => 'Starts at: ${date}';
			case 'loginAction': return 'Log in';
			case 'addPicture': return 'Add picture';
			case 'editPicture': return 'Edit picture';
			case 'exportKeys': return 'Export keys';
			case 'mutedUser': return 'Muted user';
			case 'unaccessibleContent': return 'Inaccessible content';
			case 'mutedUserDesc': return 'You have muted this user, consider unmuting to view this content';
			case 'commentHidden': return 'This comment is hidden';
			case 'upcoming': return 'Upcoming';
			case 'exportCredentials': return 'Export credentials';
			case 'loginToYakihonne': return 'Log in to Yakihonne';
			case 'alreadyUser': return 'Already a user?';
			case 'createPoll': return 'Create poll';
			case 'gasStationTotal': return 'Gas station (total funded)';
			case 'gasStationRemaining': return 'Gas station (remaining balance)';
			case 'paste': return 'Paste';
			case 'manual': return 'Manual';
			case 'contacts': return 'Contacts';
			case 'typeManualDesc': return 'Type lightning Address, Lightning invoice or LNURL';
			case 'useValidPaymentRequest': return 'Please use valid payment request';
			case 'save': return 'Save';
			case 'saveImageGallery': return 'Image has been downloaded to your gallery';
			case 'errorSavingImage': return 'Error occured while downloading the image';
			case 'copyImageGallery': return 'Image has been copied to your Clipboard';
			case 'errorCopyImage': return 'Error occured while copying the image';
			case 'scan': return 'Scan';
			case 'invalidLightningAddress': return 'Invalid lightning address';
			case 'deleteAccountDesc': return 'You are about to delete your account, do you wish to proceed?';
			case 'paymentFailedInvoice': return 'Payment failed: check the validity of this invoice';
			case 'validSatsAmount': return 'Set a valid sats amount';
			case 'placeholder': return 'Placeholder';
			case 'inputFieldCustomization': return 'Input field customization';
			case 'addInputField': return 'Add input field';
			case 'addButton': return 'Add button';
			case 'selectImage': return 'Select image';
			case 'moveLeft': return 'Move left';
			case 'moveRight': return 'Move right';
			case 'buttonRequired': return 'There should be at least one button available';
			case 'missingInputDesc': return 'It looks like you\'re using one of the custom functions that requires an input field component without embedding one in your smart widget, please add an input field so the function works properly.';
			case 'countdown': return 'Countdown';
			case 'contentEndsAt': return 'Content ends at';
			case 'countdownTime': return 'Countdown time is mandatory';
			case 'contentEndsDate': return 'Content ends date is mandatory';
			case 'lnMandatory': return 'Lightning address is mandatory';
			case 'pubkeysMandatory': return 'At least one profile is mandatory';
			case 'buttonNoUrl': return 'Buttons urls are mandatory';
			case 'shareWidgetImage': return 'Share widget image';
			case 'inputField': return 'Input field';
			case 'noReplies': return 'No replies';
			case 'message': return 'Message';
			case 'chat': return 'Chat';
			case 'onlyLettersNumber': return 'Only letters & numbers allowed';
			case 'appCache': return 'App cache';
			case 'cachedData': return 'Cached data';
			case 'cachedMedia': return 'Cached media';
			case 'cacheCleared': return 'Cache has been cleared';
			case 'closeAppClearingCache': return 'It is preferable to restart the app upon clearing cache to ensure all changes take effect and the app runs smoothly';
			case 'appCacheNotice': return 'Your app cache is growing in size. To ensure smooth performance, it\'s recommended to clear old data.';
			case 'manageCache': return 'Manage cache';
			case 'filterByTime': return 'Filter by time';
			case 'allTime': return 'All time';
			case 'oneMonth': return '1 month';
			case 'threeMonths': return '3 months';
			case 'sixMonths': return '6 months';
			case 'oneYear': return '1 year';
			case 'defaultZapAmount': return 'Default zap amount';
			case 'oneTapZap': return 'Enable one tap zap';
			case 'verify': return 'Verify';
			case 'reset': return 'reset';
			case 'appCannotVerified': return 'App cannot be verified or invalid';
			case 'useValidAppUrl': return 'Use a valid app url';
			case 'app': return 'App';
			case 'userNotConnected': return 'User not connected';
			case 'userCannotSignEvent': return 'This user cannot sign events.';
			case 'invalidEvent': return 'Invalid event';
			case 'eventCannotBeSigned': return 'Event cannot be signed';
			case 'signEvent': return 'Sign event';
			case 'sign': return 'Sign';
			case 'signPublish': return 'Sign & publish';
			case 'signEventDes': return 'You are about to sign the following event';
			case 'enableAutomaticSigning': return 'Automatic signing';
			case 'tools': return 'Tools';
			case 'searchSmartWidgets': return 'Search for smart widgets';
			case 'noToolsAvailable': return 'No tools available';
			case 'underMaintenance': return 'Under maintenance';
			case 'smartWidgetMaintenance': return 'Smart Widget is down for maintenance. We\'re fixing it up and will have it back soon!';
			case 'mySavedTools': return 'My saved tools';
			case 'availableTools': return 'Available tools';
			case 'remove': return 'Remove';
			case 'youHaveNoTools': return 'You have no tools';
			case 'discoverTools': return 'Discover published tools to help you with your content creation';
			case 'addWidgetTools': return 'Add widget tools';
			case 'widgetSearch': return 'Widget search';
			case 'widgetSearchDesc': return 'searching for published smart widgets and what people made';
			case 'getInspired': return 'Get inspired';
			case 'getInspirtedDesc': return 'ask our AI to help you build your smart widget';
			case 'trySearch': return 'Try out different methods of searching';
			case 'typeForCommands': return 'Type / for commands';
			case 'loadMore': return 'Load more';
			case 'searchingFor': return ({required Object name}) => 'Search for: ${name}';
			case 'playground': return 'Playground';
			case 'typeKeywords': return 'Type keywords (ie: Keyword1, Keyword2..)';
			case 'enableGossip': return 'Gossip model';
			case 'enableGossipDesc': return 'Gossip model is disabled by default. You can enable it, in Settings, under Content moderation.';
			case 'enableExternalBrowser': return 'Use external browser';
			case 'restartAppTakeEffect': return 'Restart the app for the action to take effect';
			case 'tips': return 'Tips';
			case 'docs': return 'Docs';
			case 'tryMiniApp': return 'Try out your mini-app with hands-on, interactive testing.';
			case 'exploreOurRepos': return 'Explore our repos or check our Smart Widgets docs.';
			case 'bringAi': return 'We\'re bringing AI!';
			case 'bringAiDesc': return 'We\'re crafting an AI assistant to streamline your work with programmable widgets and mini-app development—keep an eye out!';
			case 'notesCount': return ({required Object number}) => '${number} note(s)';
			case 'mixedContentCount': return ({required Object number}) => '${number} content';
			case 'noApp': return 'No suited app can be found to open the exported file';
			case 'andMore': return ({required Object number}) => '& ${number} other(s)';
			case 'addFilter': return 'Add filter';
			case 'entitleFilter': return 'Entitle of filter';
			case 'includedWords': return 'Included words';
			case 'excludedWords': return 'Excluded words';
			case 'hideSensitiveContent': return 'Hide sensitive content';
			case 'mustIncludeThumbnail': return 'Must include thumbnail';
			case 'forArticles': return 'For articles';
			case 'forVideos': return 'For videos';
			case 'forCurations': return 'For curations';
			case 'articleMinWords': return 'Content minimum words count';
			case 'showOnlyArticleMedia': return 'Show only articles with media';
			case 'showOnlyNotesMedia': return 'Show only notes with media';
			case 'curationsType': return 'Curations type';
			case 'minItemCount': return 'Minimum items count';
			case 'addWord': return 'Add a proper word';
			case 'wordNotInIncluded': return 'Make sure the word is not in the included words';
			case 'wordNotInExcluded': return 'Make sure the word is not in the excluded words';
			case 'fieldRequired': return 'Field required';
			case 'filterAdded': return 'Filter has been added';
			case 'filterUpdated': return 'Filter has been updated';
			case 'filterDeleted': return 'Filter has been deleted';
			case 'filters': return 'Filters';
			case 'contentFeed': return 'Content feed';
			case 'communityFeed': return 'Community feed';
			case 'relaysFeed': return 'Relays feed';
			case 'marketplaceFeed': return 'Marketplace feed';
			case 'addYourFeed': return 'Add your preferred feed';
			case 'myList': return 'My list';
			case 'allFreeFeeds': return 'All free feeds';
			case 'noRelays': return 'No relays are present';
			case 'addRelays': return 'Add your relay list to enjoy a clean and custom feed';
			case 'adjustYourFeedList': return 'Adjust your feed list';
			case 'addRelayUrl': return 'Add relay url';
			case 'feedOptionEnabled': return 'At least one feed option should be enabled';
			case 'feedSetUpdate': return 'Feed set has been updated';
			case 'global': return 'Global';
			case 'fromNetwork': return 'From network';
			case 'top': return 'Top';
			case 'showFollowingList': return 'Your current feed is based on someone else\'s following list, start following people to tailor your feed on your preference';
			case 'from': return 'From';
			case 'to': return 'To';
			case 'dayMonthYear': return 'dd/MM/yyyy';
			case 'fromDateMessage': return '\'From\' date must be earlier than \'To\' date';
			case 'toDateMessage': return '\'To\' date must be later than \'From\' date';
			case 'noResults': return 'No results';
			case 'noResultsFilterMessage': return 'It looks like you\'re applying a custom filter, please adjust the parameters and dates to acquire more data';
			case 'noResultsNoFilterMessage': return 'Nothing was found, please change your content source or apply different filter params';
			case 'addToNotes': return 'Add to notes';
			case 'addToDiscover': return 'Add to discover';
			case 'shareRelayContent': return 'Share relay content';
			case 'shareRelayUrl': return 'Share relay URL';
			case 'basic': return 'Basic';
			case 'privateMessages': return 'Private messages';
			case 'pushNotifications': return 'Push notifications';
			case 'repliesView': return 'Replies view';
			case 'threadView': return 'Thread';
			case 'boxView': return 'Box';
			case 'viewAs': return 'View as';
			case 'feedSettings': return 'Feed settings';
			case 'appliedFilterDesc': return 'This note is hidden due to the current applied filter.';
			case 'showNote': return 'Show note';
			case 'allMedia': return 'All media';
			case 'searchInNostr': return 'Search in Nostr';
			case 'findPeopleContent': return 'Find people, notes & content';
			case 'activeService': return 'Active service';
			case 'regularServers': return 'Regular servers';
			case 'blossomServers': return 'BLOSSOM servers';
			case 'mirrorAllServer': return 'Mirror all servers';
			case 'mainServer': return 'Main server';
			case 'select': return 'Select';
			case 'noServerFound': return 'No server found';
			case 'serverExists': return 'Server already exists on your list';
			case 'invalidUrl': return 'Invalid url format';
			case 'serverPath': return 'Server path';
			case 'errorAddingBlossom': return 'Error occured while adding blossom server';
			case 'errorSelectBlossom': return 'Error occured while selecting blossom server';
			case 'errorDeleteBlossom': return 'Error occured while deleting blossom server';
			case 'wotConfig': return 'Web of trust configuration';
			case 'wot': return 'web of trust';
			case 'wotThreshold': return 'Web of trust threshold';
			case 'postActions': return 'Post actions';
			case 'enabledFor': return 'Enabled for';
			case 'dmRelayTitle': return 'Private messages relays are not configured!';
			case 'dmRelayDesc': return 'Update your relays list accordingly. ';
			case 'youFollow': return 'You follow';
			case 'quotaLimit': return 'You have exceeded your daily quota limit';
			case 'alwaysUseExternal': return 'Always use external wallet zaps';
			case 'alwaysUseExternalDesc': return 'Use an external Lightning wallet app instead of YakiHonne\'s built-in wallet for all zap transactions.';
			case 'unreachableExternalWallet': return 'Unreachable external wallet';
			case 'secureStorageDesc': return 'Your keys are stored securely on your device and never shared with us or anyone else.';
			case 'pubkeySharedDesc': return 'Safe to share - this identifies you on Nostr.';
			case 'privKeyDesc': return 'Keep private - backup securely to access your account elsewhere.';
			case 'settingsKeysDesc': return 'Manage your Nostr keys for network identity, event signing, and post authentication.';
			case 'settingsRelaysDesc': return 'Configure Nostr relay connections for storing and distributing events.';
			case 'settingsCustomizationDesc': return 'Personalize your YakiHonne feed display, gestures, previews, and preferences for better Nostr experience.';
			case 'settingsNotificationsDesc': return 'Control notifications for messages, mentions, reactions, and other Nostr events.';
			case 'settingsContentDesc': return 'Control content interactions, privacy settings, media handling, and messaging preferences on Nostr.';
			case 'settingsLanguageDesc': return 'Choose your preferred language for YakiHonne interface and content translation.';
			case 'settingsWalletDesc': return 'Connect and manage Bitcoin Lightning wallets for sending/receiving zaps with customizable amounts and external integration.';
			case 'settingsAppearanceDesc': return 'Customize YakiHonne\'s visual appearance to match your preferences and viewing comfort.';
			case 'settingsCacheDesc': return 'Manage app performance monitoring, error reporting, and storage optimization for smooth operation.';
			case 'addQuickRelayDesc': return 'Quickly add a new relay by entering its URL.';
			case 'fewerRelays': return 'Fewer stable relays = better performance and faster syncing.';
			case 'greenDotsDesc': return 'Green dots show active connections.';
			case 'redDotsDesc': return 'Red dots show offline relays.';
			case 'greyDotsDesc': return 'Grey dots show pending relays.';
			case 'homeFeedCustomDesc': return 'Choose reply display style (Box or Thread) and manage suggestion preferences for people, content, and interests.';
			case 'NewPostDesc': return 'Choose what happens when you long-press while creating posts (currently set to Note).';
			case 'profilePreviewDesc': return 'Show user profile previews when tapping usernames in your feed.';
			case 'collapseNoteDesc': return 'Automatically minimize long posts to keep your feed clean and readable.';
			case 'pushNotificationsDesc': return 'Get instant alerts on your device. Privacy-focused using secure FCM and APNS protocols';
			case 'privateMessagesDesc': return 'Get alerted for new direct messages and private conversations.';
			case 'followingDesc': return 'Get notified when people you follow post new content.';
			case 'mentionsDesc': return 'Get alerted when someone mentions you or replies to your posts.';
			case 'repostsDesc': return 'Get alerted when someone shares or reposts your content.';
			case 'reactionsDesc': return 'Get notified when some likes or react to your posts.';
			case 'zapDesc': return 'Get notified when you receive Bitcoin tips (zaps) on your posts.';
			case 'muteListDesc': return 'View and manage users you\'ve blocked from appearing in your feed.';
			case 'mediaUploaderDesc': return 'Choose which service uploads your images and media files.';
			case 'autoSignDesc': return 'Automatically sign events requested by mini apps (action/tool smart widgets) without manual confirmation each time.';
			case 'gossipDesc': return 'Sophisticated relay management that automatically finds your followees\' posts across different relays while minimizing connections and adapting to offline relays.';
			case 'useExternalBrowsDesc': return 'Open links in your default browser app instead of the built-in browser.';
			case 'secureDmDesc': return 'Use the latest private messaging standard (NIP-17) with advanced encryption. Disable to use the older NIP-4 format for compatibility.';
			case 'wotConfigDesc': return 'A decentralized trust mechanism using social attestations to establish reputation within the Nostr protocol.';
			case 'appLangDesc': return 'Choose the language for YakiHonne\'s interface, menus, and buttons.';
			case 'contentTransDesc': return 'Select translation service for posts in foreign languages.';
			case 'planDesc': return 'Your current translation plan tier and usage limits.';
			case 'manageWalletsDesc': return 'Add and organize your Lightning wallets for sending and receiving Bitcoin zaps on Nostr.';
			case 'defaultZapDesc': return 'Set the default Bitcoin amount (in sats) when sending quick zaps to posts.';
			case 'enableZapDesc': return 'One tap sends default amount instantly. Double tap opens zap options (amount, wallet, message). When disabled, double tap sends default amount.';
			case 'externalWalletDesc': return 'Use an external Lightning wallet app instead of YakiHonne\'s built-in wallet for all zap transactions.';
			case 'fontSizeDesc': return 'Adjust text size throughout the app for better readability - use the slider to make text larger or smaller.';
			case 'appThemeDesc': return 'Switch between light and dark mode to customize the app\'s visual appearance.';
			case 'crashlyticsDesc': return 'Anonymous crash reporting and app analytics to help improve performance and fix bugs. We use Umami analytics to improve your experience. Opt out anytime.';
			case 'showSuggDesc': return 'Display general content recommendations in your feed.';
			case 'showSuggPeople': return 'Show recommended users to follow based on your activity.';
			case 'showSuggContent': return 'Display recommended posts and articles in your feed.';
			case 'showSuggInterests': return 'Show topic and interest recommendations for discovery.';
			case 'striveToMake': return 'We strive to make the best out of Nostr, Support us below or send us your valuable feed: zap, dms, github.';
			case 'errorAmber': return 'You either rejected or you are already connected with amber';
			case 'useOneRelay': return 'You should at least leave one relay connected';
			case 'automaticPurge': return 'Automatic cache purge';
			case 'automaticPurgeDesc': return 'Auto-clear app cache when it reaches 2GB. Maintains performance and prevents excessive storage usage.';
			case 'customServices': return 'Custom services';
			case 'defaultServices': return 'Default services';
			case 'addService': return 'Add service';
			case 'customServicesDesc': return 'Available custom services added by you.';
			case 'urlRequired': return 'Url required';
			case 'serviceAdded': return 'Service has been added';
			case 'showRawEvent': return 'Show raw event';
			case 'rawEventData': return 'Raw event data';
			case 'copyRawEventData': return 'Raw event data was copied! 👏';
			case 'kind': return 'Kind';
			case 'shortNote': return 'Short note';
			case 'postedOnDate': return 'Posted on';
			case 'showMore': return '... show more';
			case 'accountDeleted': return 'This account has been deleted and can no longer be accessed.';
			case 'ok': return 'OK';
			case 'redeem': return 'Redeem';
			case 'redeemCode': return 'Redeem code';
			case 'redeemAndEarn': return 'Redeem & Earn';
			case 'redeemingFailed': return 'Redeeming failed';
			case 'redeemInProgress': return 'Redeeming code in progress...';
			case 'redeemCodeDesc': return 'Enter your code to redeem it';
			case 'missingCode': return 'Missing code';
			case 'missingPubkey': return 'Missing pubkey';
			case 'invalidPubkey': return 'Invalid pubkey';
			case 'missingLightningAddress': return 'Missing lightning address';
			case 'codeNotFound': return 'Code not found';
			case 'redeemCodeRequired': return 'Redeem code is required';
			case 'redeemCodeInvalid': return 'Redeem code is invalid';
			case 'codeBeingRedeemed': return 'Your code is being redeemed. If it doesn\'t complete successfully, please try again shortly.';
			case 'redeemCodeSuccess': return 'Code has been successfully redeemed';
			case 'redeemFailed': return 'Could not redeem the code, please try again later.';
			case 'codeAlreadyRedeemed': return 'Code has already been redeemed';
			case 'satsEarned': return ({required Object amount}) => '+${amount} sats earned.';
			case 'selectReceivingWallet': return 'Select receiving wallet';
			case 'redeemCodeMessage': return 'Claim free sats with YakiHonne redeemable codes — simply enter your code and boost your balance instantly.';
			case 'scanCode': return 'Scan code';
			case 'enterCode': return 'Enter code';
			case 'errorSharingMedia': return 'Error occured while sharing media';
			case 'open': return 'Open';
			case 'openUrl': return 'Open URL';
			case 'openUrlDesc': return ({required Object url}) => 'Do you want to open "${url}"?';
			case 'openUrlPrompt': return 'Open url prompt';
			case 'openUrlPromptDesc': return 'A safety prompt that displays the full URL before opening it in your browser.';
			case 'waitingForNetwork': return 'Waiting for network...';
			case 'whatsNew': return 'What\'s new';
			case 'appCustom': return 'App custom';
			case 'poll': return 'Poll';
			case 'pendingEvents': return 'Pending events';
			case 'pendingEventsDesc': return 'Pending events are created while offline or with poor connection. They\'ll be automatically sent when your internet connection is restored.';
			case 'singleColumnFeed': return 'Single column feed';
			case 'singleColumnFeedDesc': return 'Show the home feed as a single wide column for better readability.';
			case 'waitingPayment': return 'Waiting for payment';
			case 'copyId': return 'Copy id';
			case 'idCopied': return 'Id was copied! 👏';
			case 'republish': return 'Republish';
			case 'useRelayRepublish': return 'You should at least choose one relay to republish to.';
			case 'republishSucces': return 'Event has been republished successfully!';
			case 'errorRepublishEvent': return 'Error occured while republishing event';
			case 'remoteSigner': return 'Remote signer';
			case 'amber': return 'Amber';
			case 'useUrlBunker': return 'Use the below URL to connect to your bunker';
			case 'or': return 'Or';
			case 'messagesDisabled': return 'Messages are disabled';
			case 'messagesDisabledDesc': return 'You are connected with a remote signer. Direct messages may contain large amounts of data and might not work properly. For the best experience, please use a local signer to enable direct messaging.';
			case 'sharedOn': return ({required Object date}) => 'Shared on ${date}';
			case 'shareAsImage': return 'Share as image';
			case 'viewOptions': return 'View options';
			case 'feedCustomization': return 'Feed customization';
			case 'defaultReaction': return 'Default reaction';
			case 'defaultReactionDesc': return 'Set a default reaction to react to posts.';
			case 'oneTapReaction': return 'Enable one tap reaction';
			case 'oneTapReactionDesc': return 'One tap react with the default reaction instantly. Double tap opens emojis list to choose from. When disabled, double tap sends default reaction';
			case 'sendingTo': return 'Sending to';
			case 'shareEmptyUsers': return 'Your followings list and friends will appear here for faster sharing experience';
			case 'publishOnly': return 'Publish only to';
			case 'protectedEvent': return 'Protected event';
			case 'protectedEventDesc': return 'A protected event is an event that only its author can republish. This keeps the content authentic and prevents others from copying or reissuing it.';
			case 'browseRelay': return 'Browse relay';
			case 'addFavorite': return 'Add favorite';
			case 'removeFavorite': return 'Remove favorite';
			case 'collections': return 'Collections';
			case 'online': return 'Online';
			case 'offline': return 'Offline';
			case 'network': return 'Network';
			case 'followedBy': return ({required Object number}) => 'Followed by ${number}';
			case 'favoredBy': return ({required Object number}) => 'Favored by ${number}';
			case 'requiredAuthentication': return 'Required authentication';
			case 'relayOrbits': return 'Relay orbits';
			case 'relayOrbitsDesc': return 'Browse and explore relay feeds';
			case 'people': return 'People';
			case 'youNotConnected': return 'You\'re not connected';
			case 'youNotConnectedDesc': return 'Log in to your account to browse your network relays';
			case 'checkingRelayConnectivity': return 'Checking relay connectivity';
			case 'unreachableRelay': return 'Unreachable relay';
			case 'engageWithUsers': return 'Engage to expand';
			case 'engageWithUsersDesc': return 'Engaging with more users helps you discover new relays and grow your relay list for a richer, more connected experience.';
			case 'loadingChatHistory': return 'Loading chat history...';
			case 'contentActionsOrder': return 'Content actions order';
			case 'contentActionsOrderDesc': return 'Easily rearrange your post interactions to match your preferred order.';
			case 'quotes': return 'Quotes';
			case 'eventLoading': return 'Event loading...';
			case 'loadMessages': return 'Load messages';
			case 'messagesNotLoaded': return 'Messages Not Loaded';
			case 'messagesNotLoadedDesc': return 'Messages are not loaded due to using a local remote signer, if you wish to load them, please click the button below.';
			case 'noteLoading': return 'Note loading...';
			case 'hideNonFollowedMedia': return 'Hide non-followed media';
			case 'hideNonFollowedMediaDesc': return 'Automatically hide images & videos from non-followed users until you tap to reveal.';
			case 'clickToView': return 'Click to view';
			case 'relayFeedListEmpty': return 'Relays feed list is empty';
			case 'relayFeedListEmptyDesc': return 'Add more relays to your list to enjoy a tailored feed.';
			case 'addRelay': return 'Add relays';
			case 'hiddenContent': return 'Hidden content';
			case 'hiddenContentDesc': return 'We\'ve hidden this content because you don\'t follow this account.';
			case 'enabledActions': return 'Enabled actions';
			case 'enabledActionsDesc': return 'No enabled actions available.';
			case 'fetchingNotificationEvent': return 'Fetching notification event';
			case 'notificationEventNotFound': return 'Notification event not found';
			case 'fiatCurrency': return 'Fiat currency';
			case 'fiatCurrencyDesc': return 'Convert sats into your selected fiat currency to better understand their value';
			default: return null;
		}
	}
}

