"
Bindings for resvh: https://github.com/linebender/resvg

Generated with: 
```smalltalk
CigCLibraryGenerator new
	packageName: 'ReSVG';
	prefix: 'Resvg';
	libraryName: 'resvg';
	import: '/usr/include/resvg.h';
	cExcludePath: '/usr/include';
	nameGenerator: (CigNameGenerator new withoutPrefixInFunctionName);
	constantGenerator: (CigConstantGenerator new include: 'resvg.h');
	generate.
```
"
Class {
	#name : 'LibResvg',
	#superclass : 'FFILibrary',
	#pools : [
		'ResvgConstants',
		'ResvgTypedef'
	],
	#category : 'ReSVG-Library',
	#package : 'ReSVG',
	#tag : 'Library'
}

{ #category : 'rendering' }
LibResvg class >> convertRGBAToARGB32: pixels [

	"convert to format ARGB32"
	^ ByteArray new: pixels size streamContents: [ :stream | 
		pixels
			groupsOf: 4 "RGBA"
			atATimeDo: [ :rOrig :gOrig :bOrig :aOrig | 
				| r g b a |
				
				a := aOrig.
				r := rOrig.
				g := gOrig.
				b := bOrig.
				
				a = 0 ifFalse: [
					r := ((r * a) + 127 / a) asInteger.
					g := ((g * a) + 127 / a) asInteger.
					b := ((b * a) + 127 / a) asInteger ].
				
				stream 
					nextPut: b;
					nextPut: g;
					nextPut: r;
					nextPut: a ] ]
]

{ #category : 'examples' }
LibResvg class >> example [
	<example>

	"this example requires Alexandria loaded (to convert the image to a Form)"
	^ self 
		example: './perspective/working-on-new-icons/stop.svg'
		scale: 16
]

{ #category : 'examples' }
LibResvg class >> example: fileName scale: scale [

	^ self 
		renderFormFromString: fileName asFileReference contents
		scale: scale
]

{ #category : 'rendering' }
LibResvg class >> renderFormFromString: aString [

	^ self 
		renderFormFromString: aString 
		scale: 1
]

{ #category : 'rendering' }
LibResvg class >> renderFormFromString: source scale: scale [
	| resvg options treeHolder tree err size width height stride pixels transform convertedPixels |

	resvg := LibResvg uniqueInstance.

	options := resvg options_create.
	treeHolder := ResvgRenderTree newValueHolder.
	err := resvg 
		parse_tree_from_data: source 
		len: source size
		opt: options
		tree: treeHolder.
	err = 0 ifFalse: [ 
		self error: 'Can''t parse svg.' ].
	tree := treeHolder value.

	"render the image"
	size := resvg get_image_size: tree.
	width := size width asInteger * scale.
	height := size height asInteger * scale.
	stride := width * 4.
	pixels := ByteArray new: (height * stride).
	"... with a scale"
	transform := resvg transform_identity.
	transform a: scale asFloat.
	transform d: scale asFloat.
	resvg
		renderTree: tree 
		transform: transform
		width: width
		height: height
		pixmap: pixels.
		
	resvg options_destroy: options.
	resvg tree_destroy: tree.
		
	convertedPixels := self convertRGBAToARGB32: pixels.
	^ self 
		toForm: convertedPixels 
		width: width 
		height: height
]

{ #category : 'rendering' }
LibResvg class >> toForm: convertedPixels width: width height: height [
	| stride surface surfaceFormat |
		
	"use alexandria to render"
	surfaceFormat := AeCairoSurfaceFormat argb32.
	stride := AeCairoImageSurface 
		strideForWidth: width 
		format: surfaceFormat.
	surface := AeCairoImageSurface 
		newForData: convertedPixels 
		format: surfaceFormat
		width: width 
		height: height 
		stride: stride.
	"get the form"
	^ surface asForm
]

{ #category : 'public - resvg' }
LibResvg >> get_image_bboxTree: tree bbox: bbox [
	"/**
	 * @brief Returns an image bounding box.
	 *
	 * This bounding box contains the maximum SVG dimensions.
	 * It's size can be bigger or smaller than #resvg_get_image_size
	 * Use it when you want to avoid clipping of elements that are outside the SVG viewbox.
	 *
	 * @param tree Render tree.
	 * @param bbox Image's bounding box.
	 * @return `false` if an image has no elements.
	 */"

	^ self ffiCall: #(int resvg_get_image_bbox(resvg_render_tree* tree, resvg_rect* bbox))
]

{ #category : 'public - resvg' }
LibResvg >> get_image_size: tree [
	"/**
	 * @brief Returns an image size.
	 *
	 * The size of an image that is required to render this SVG.
	 *
	 * Note that elements outside the viewbox will be clipped. This is by design.
	 * If you want to render the whole SVG content, use #resvg_get_image_bbox instead.
	 *
	 * @param tree Render tree.
	 * @return Image size.
	 */"

	^ self ffiCall: #(resvg_size resvg_get_image_size(resvg_render_tree* tree))
]

{ #category : 'public - resvg' }
LibResvg >> get_node_bboxTree: tree id: id bbox: bbox [
	"/**
	 * @brief Returns node's bounding box in canvas coordinates by ID.
	 *
	 * @param tree Render tree.
	 * @param id Node's ID. Must not be NULL.
	 * @param bbox Node's bounding box.
	 * @return `false` if a node with such an ID does not exist
	 * @return `false` if ID isn't a UTF-8 string.
	 * @return `false` if ID is an empty string
	 */"

	^ self ffiCall: #(int resvg_get_node_bbox(resvg_render_tree* tree, const char* id, resvg_rect* bbox))
]

{ #category : 'public - resvg' }
LibResvg >> get_node_stroke_bboxTree: tree id: id bbox: bbox [
	"/**
	 * @brief Returns node's bounding box, including stroke, in canvas coordinates by ID.
	 *
	 * @param tree Render tree.
	 * @param id Node's ID. Must not be NULL.
	 * @param bbox Node's bounding box.
	 * @return `false` if a node with such an ID does not exist
	 * @return `false` if ID isn't a UTF-8 string.
	 * @return `false` if ID is an empty string
	 */"

	^ self ffiCall: #(int resvg_get_node_stroke_bbox(resvg_render_tree* tree, const char* id, resvg_rect* bbox))
]

{ #category : 'public - resvg' }
LibResvg >> get_node_transformTree: tree id: id transform: transform [
	"/**
	 * @brief Returns node's transform by ID.
	 *
	 * @param tree Render tree.
	 * @param id Node's ID. UTF-8 string. Must not be NULL.
	 * @param transform Node's transform.
	 * @return `true` if a node exists.
	 * @return `false` if a node doesn't exist or ID isn't a UTF-8 string.
	 * @return `false` if a node exists, but not renderable.
	 */"

	^ self ffiCall: #(int resvg_get_node_transform(resvg_render_tree* tree, const char* id, resvg_transform* transform))
]

{ #category : 'public - resvg' }
LibResvg >> get_object_bboxTree: tree bbox: bbox [
	"/**
	 * @brief Returns an object bounding box.
	 *
	 * This bounding box does not include objects stroke and filter regions.
	 * This is what SVG calls ""absolute object bonding box"".
	 *
	 * If you're looking for a ""complete"" bounding box see #resvg_get_image_bbox
	 *
	 * @param tree Render tree.
	 * @param bbox Image's object bounding box.
	 * @return `false` if an image has no elements.
	 */"

	^ self ffiCall: #(int resvg_get_object_bbox(resvg_render_tree* tree, resvg_rect* bbox))
]

{ #category : 'public - resvg' }
LibResvg >> init_log [
	"/**
	 * @brief Initializes the library log.
	 *
	 * Use it if you want to see any warnings.
	 *
	 * Must be called only once.
	 *
	 * All warnings will be printed to the `stderr`.
	 */"

	self ffiCall: #(void resvg_init_log())
]

{ #category : 'public - resvg' }
LibResvg >> is_image_empty: tree [
	"/**
	 * @brief Checks that tree has any nodes.
	 *
	 * @param tree Render tree.
	 * @return Returns `true` if tree has no nodes.
	 */"

	^ self ffiCall: #(int resvg_is_image_empty(resvg_render_tree* tree))
]

{ #category : 'accessing - platform' }
LibResvg >> macLibraryName [

	^ FFIMacLibraryFinder new
		userPaths: #('./CIG/lib');
		findLibrary: 'libresvg.0.46.dylib'
]

{ #category : 'public - resvg' }
LibResvg >> node_existsTree: tree id: id [
	"/**
	 * @brief Returns `true` if a renderable node with such an ID exists.
	 *
	 * @param tree Render tree.
	 * @param id Node's ID. UTF-8 string. Must not be NULL.
	 * @return `true` if a node exists.
	 * @return `false` if a node doesn't exist or ID isn't a UTF-8 string.
	 * @return `false` if a node exists, but not renderable.
	 */"

	^ self ffiCall: #(int resvg_node_exists(resvg_render_tree* tree, const char* id))
]

{ #category : 'public - resvg' }
LibResvg >> options_create [
	"/**
	 * @brief Creates a new #resvg_options object.
	 *
	 * Should be destroyed via #resvg_options_destroy.
	 */"

	^ self ffiCall: #(resvg_options* resvg_options_create())
]

{ #category : 'public - resvg' }
LibResvg >> options_destroy: opt [
	"/**
	 * @brief Destroys the #resvg_options.
	 */"

	self ffiCall: #(void resvg_options_destroy(resvg_options* opt))
]

{ #category : 'public - resvg' }
LibResvg >> options_load_font_dataOpt: opt data: data len: len [
	"/**
	 * @brief Loads a font data into the internal fonts database.
	 *
	 * Prints a warning into the log when the data is not a valid TrueType font.
	 *
	 * Has no effect when the `text` feature is not enabled.
	 */"

	self ffiCall: #(void resvg_options_load_font_data(resvg_options* opt, const char* data, uintptr_t len))
]

{ #category : 'public - resvg' }
LibResvg >> options_load_font_fileOpt: opt file_path: file_path [
	"/**
	 * @brief Loads a font file into the internal fonts database.
	 *
	 * Prints a warning into the log when the data is not a valid TrueType font.
	 *
	 * Has no effect when the `text` feature is not enabled.
	 *
	 * @return #resvg_error with RESVG_OK, RESVG_ERROR_NOT_AN_UTF8_STR or RESVG_ERROR_FILE_OPEN_FAILED
	 */"

	^ self ffiCall: #(int32_t resvg_options_load_font_file(resvg_options* opt, const char* file_path))
]

{ #category : 'public - resvg' }
LibResvg >> options_load_system_fonts: opt [
	"/**
	 * @brief Loads system fonts into the internal fonts database.
	 *
	 * This method is very IO intensive.
	 *
	 * This method should be executed only once per #resvg_options.
	 *
	 * The system scanning is not perfect, so some fonts may be omitted.
	 * Please send a bug report in this case.
	 *
	 * Prints warnings into the log.
	 *
	 * Has no effect when the `text` feature is not enabled.
	 */"

	self ffiCall: #(void resvg_options_load_system_fonts(resvg_options* opt))
]

{ #category : 'public - resvg' }
LibResvg >> options_set_cursive_familyOpt: opt family: family [
	"/**
	 * @brief Sets the `cursive` font family.
	 *
	 * Must be UTF-8. NULL is not allowed.
	 *
	 * Has no effect when the `text` feature is not enabled.
	 *
	 * Default: Comic Sans MS
	 */"

	self ffiCall: #(void resvg_options_set_cursive_family(resvg_options* opt, const char* family))
]

{ #category : 'public - resvg' }
LibResvg >> options_set_dpiOpt: opt dpi: dpi [
	"/**
	 * @brief Sets the target DPI.
	 *
	 * Impact units conversion.
	 *
	 * Default: 96
	 */"

	self ffiCall: #(void resvg_options_set_dpi(resvg_options* opt, float dpi))
]

{ #category : 'public - resvg' }
LibResvg >> options_set_fantasy_familyOpt: opt family: family [
	"/**
	 * @brief Sets the `fantasy` font family.
	 *
	 * Must be UTF-8. NULL is not allowed.
	 *
	 * Has no effect when the `text` feature is not enabled.
	 *
	 * Default: Papyrus on macOS, Impact on other OS'es
	 */"

	self ffiCall: #(void resvg_options_set_fantasy_family(resvg_options* opt, const char* family))
]

{ #category : 'public - resvg' }
LibResvg >> options_set_font_familyOpt: opt family: family [
	"/**
	 * @brief Sets the default font family.
	 *
	 * Will be used when no `font-family` attribute is set in the SVG.
	 *
	 * Must be UTF-8. NULL is not allowed.
	 *
	 * Default: Times New Roman
	 */"

	self ffiCall: #(void resvg_options_set_font_family(resvg_options* opt, const char* family))
]

{ #category : 'public - resvg' }
LibResvg >> options_set_font_sizeOpt: opt size: size [
	"/**
	 * @brief Sets the default font size.
	 *
	 * Will be used when no `font-size` attribute is set in the SVG.
	 *
	 * Default: 12
	 */"

	self ffiCall: #(void resvg_options_set_font_size(resvg_options* opt, float size))
]

{ #category : 'public - resvg' }
LibResvg >> options_set_image_rendering_modeOpt: opt mode: mode [
	"/**
	 * @brief Sets the default image rendering method.
	 *
	 * Will be used when an SVG element's `image-rendering` property is set to `auto`.
	 *
	 * Default: `RESVG_IMAGE_RENDERING_OPTIMIZE_QUALITY`
	 */"

	self ffiCall: #(void resvg_options_set_image_rendering_mode(resvg_options* opt, resvg_image_rendering mode))
]

{ #category : 'public - resvg' }
LibResvg >> options_set_languagesOpt: opt languages: languages [
	"/**
	 * @brief Sets a comma-separated list of languages.
	 *
	 * Will be used to resolve a `systemLanguage` conditional attribute.
	 *
	 * Example: en,en-US.
	 *
	 * Must be UTF-8. Can be NULL.
	 *
	 * Default: en
	 */"

	self ffiCall: #(void resvg_options_set_languages(resvg_options* opt, const char* languages))
]

{ #category : 'public - resvg' }
LibResvg >> options_set_monospace_familyOpt: opt family: family [
	"/**
	 * @brief Sets the `monospace` font family.
	 *
	 * Must be UTF-8. NULL is not allowed.
	 *
	 * Has no effect when the `text` feature is not enabled.
	 *
	 * Default: Courier New
	 */"

	self ffiCall: #(void resvg_options_set_monospace_family(resvg_options* opt, const char* family))
]

{ #category : 'public - resvg' }
LibResvg >> options_set_resources_dirOpt: opt path: path [
	"/**
	 * @brief Sets a directory that will be used during relative paths resolving.
	 *
	 * Expected to be the same as the directory that contains the SVG file,
	 * but can be set to any.
	 *
	 * Must be UTF-8. Can be set to NULL.
	 *
	 * Default: NULL
	 */"

	self ffiCall: #(void resvg_options_set_resources_dir(resvg_options* opt, const char* path))
]

{ #category : 'public - resvg' }
LibResvg >> options_set_sans_serif_familyOpt: opt family: family [
	"/**
	 * @brief Sets the `sans-serif` font family.
	 *
	 * Must be UTF-8. NULL is not allowed.
	 *
	 * Has no effect when the `text` feature is not enabled.
	 *
	 * Default: Arial
	 */"

	self ffiCall: #(void resvg_options_set_sans_serif_family(resvg_options* opt, const char* family))
]

{ #category : 'public - resvg' }
LibResvg >> options_set_serif_familyOpt: opt family: family [
	"/**
	 * @brief Sets the `serif` font family.
	 *
	 * Must be UTF-8. NULL is not allowed.
	 *
	 * Has no effect when the `text` feature is not enabled.
	 *
	 * Default: Times New Roman
	 */"

	self ffiCall: #(void resvg_options_set_serif_family(resvg_options* opt, const char* family))
]

{ #category : 'public - resvg' }
LibResvg >> options_set_shape_rendering_modeOpt: opt mode: mode [
	"/**
	 * @brief Sets the default shape rendering method.
	 *
	 * Will be used when an SVG element's `shape-rendering` property is set to `auto`.
	 *
	 * Default: `RESVG_SHAPE_RENDERING_GEOMETRIC_PRECISION`
	 */"

	self ffiCall: #(void resvg_options_set_shape_rendering_mode(resvg_options* opt, resvg_shape_rendering mode))
]

{ #category : 'public - resvg' }
LibResvg >> options_set_stylesheetOpt: opt content: content [
	"/**
	 * @brief Provides the content of a stylesheet that will be used when resolving CSS attributes.
	 *
	 * Must be UTF-8. Can be set to NULL.
	 *
	 * Default: NULL
	 */"

	self ffiCall: #(void resvg_options_set_stylesheet(resvg_options* opt, const char* content))
]

{ #category : 'public - resvg' }
LibResvg >> options_set_text_rendering_modeOpt: opt mode: mode [
	"/**
	 * @brief Sets the default text rendering method.
	 *
	 * Will be used when an SVG element's `text-rendering` property is set to `auto`.
	 *
	 * Default: `RESVG_TEXT_RENDERING_OPTIMIZE_LEGIBILITY`
	 */"

	self ffiCall: #(void resvg_options_set_text_rendering_mode(resvg_options* opt, resvg_text_rendering mode))
]

{ #category : 'public - resvg' }
LibResvg >> parse_tree_from_data: data len: len opt: opt tree: tree [
	"/**
	 * @brief Creates #resvg_render_tree from data.
	 *
	 * See #resvg_is_image_empty for details.
	 *
	 * @param data SVG data. Can contain SVG string or gzip compressed data. Must not be NULL.
	 * @param len Data length.
	 * @param opt Rendering options. Must not be NULL.
	 * @param tree Parsed render tree. Should be destroyed via #resvg_tree_destroy.
	 * @return #resvg_error
	 */"

	^ self ffiCall: #(int32_t resvg_parse_tree_from_data(const char* data, uintptr_t len, resvg_options* opt, resvg_render_tree* tree))
]

{ #category : 'public - resvg' }
LibResvg >> parse_tree_from_fileFile_path: file_path opt: opt tree: tree [
	"/**
	 * @brief Creates #resvg_render_tree from file.
	 *
	 * .svg and .svgz files are supported.
	 *
	 * See #resvg_is_image_empty for details.
	 *
	 * @param file_path UTF-8 file path.
	 * @param opt Rendering options. Must not be NULL.
	 * @param tree Parsed render tree. Should be destroyed via #resvg_tree_destroy.
	 * @return #resvg_error
	 */"

	^ self ffiCall: #(int32_t resvg_parse_tree_from_file(const char* file_path, resvg_options* opt, resvg_render_tree* tree))
]

{ #category : 'public - resvg' }
LibResvg >> renderTree: tree transform: transform width: width height: height pixmap: pixmap [
	"/**
	 * @brief Renders the #resvg_render_tree onto the pixmap.
	 *
	 * @param tree A render tree.
	 * @param transform A root SVG transform. Can be used to position SVG inside the `pixmap`.
	 * @param width Pixmap width.
	 * @param height Pixmap height.
	 * @param pixmap Pixmap data. Should have width*height*4 size and contain
	 *               premultiplied RGBA8888 pixels.
	 */"

	self ffiCall: #(void resvg_render(resvg_render_tree* tree, resvg_transform transform, uint32_t width, uint32_t height, char*  pixmap))
]

{ #category : 'public - resvg' }
LibResvg >> render_nodeTree: tree id: id transform: transform width: width height: height pixmap: pixmap [
	"/**
	 * @brief Renders a Node by ID onto the image.
	 *
	 * @param tree A render tree.
	 * @param id Node's ID. Must not be NULL.
	 * @param transform A root SVG transform. Can be used to position SVG inside the `pixmap`.
	 * @param width Pixmap width.
	 * @param height Pixmap height.
	 * @param pixmap Pixmap data. Should have width*height*4 size and contain
	 *               premultiplied RGBA8888 pixels.
	 * @return `false` when `id` is not a non-empty UTF-8 string.
	 * @return `false` when the selected `id` is not present.
	 * @return `false` when an element has a zero bbox.
	 */"

	^ self ffiCall: #(int resvg_render_node(resvg_render_tree* tree, const char* id, resvg_transform transform, uint32_t width, uint32_t height, char* pixmap))
]

{ #category : 'accessing' }
LibResvg >> runner [
	
	^ TFSameThreadRunner uniqueInstance
]

{ #category : 'public - resvg' }
LibResvg >> transform_identity [
	"/**
	 * @brief Creates an identity transform.
	 */"

	^ self ffiCall: #(resvg_transform resvg_transform_identity())
]

{ #category : 'public - resvg' }
LibResvg >> tree_destroy: tree [
	"/**
	 * @brief Destroys the #resvg_render_tree.
	 */"

	self ffiCall: #(void resvg_tree_destroy(resvg_render_tree* tree))
]

{ #category : 'accessing - platform' }
LibResvg >> unix64LibraryName [

	^ FFIUnix64LibraryFinder new
		userPaths: #('./CIG/lib');
		findLibrary: 'libresvg.so'
]

{ #category : 'accessing - platform' }
LibResvg >> win32LibraryName [

	^ FFIWindowsLibraryFinder new
		userPaths: #('./CIG/lib');
		findLibrary: 'resvg.dll'
]
