//
//  AKFunctions.m
//  testestest
//
//  Created by Олег on 29.02.16.
//  Copyright © 2016 Admin. All rights reserved.
//

#import "NSCostelique.h"
#import <objc/runtime.h>
#import <SystemConfiguration/SystemConfiguration.h>

#ifndef DEBUG
#define AK_DEBUG 1
#define DEBUG_INTERFACE @interface DebugProxy : NSProxy @end @implementation DebugProxy \
void runDebug(void); +(void)load { if (AK_DEBUG) { runDebug(); } } @end
#define STORED_BYTES @"20202020 202a2020 20202020 20202020 20202020 20202020 2a0a2020 20202020 2020205f 5f202020 20202020 20202020 20202020 202a0a20 20202020 202c6462 27202020 202a2020 2020202a 0a202020 20202c64 382f2020 20202020 202a2020 20202020 20202a20 2020202a 0a202020 20203838 380a2020 20202060 64625c20 20202020 20202a20 20202020 2a0a2020 20202020 20606f60 5f202020 20202020 20202020 20202020 20202020 202a2a0a 20202a20 20202020 20202020 20202020 20202a20 20202a20 2020205f 20202020 20202a0a 20202020 20202020 2a202020 20202020 20202020 20202020 20202f20 290a2020 2020202a 20202020 285c5f5f 2f29202a 20202020 20202028 20282020 2a0a2020 202c2d2e 2c2d2e2c 29202020 20282e2c 2d2e2c2d 2e2c2d2e 2920292e 2c2d2e2c 2d2e0a20 207c2040 7c20203d 7b202020 2020207d 3d207c20 407c2020 2f202f20 7c20407c 6f207c0a 205f6a5f 5f6a5f5f 6a5f2920 20202020 602d2d2d 2d2d2d2d 2f202f5f 5f6a5f5f 6a5f5f6a 5f0a205f 5f5f5f5f 5f5f5f28 20202020 20202020 20202020 2020202f 5f5f5f5f 5f5f5f5f 5f5f5f0a 20207c20 207c2040 7c205c20 20202020 20202020 20202020 207c7c20 6f7c4f20 7c20407c 0a20207c 6f207c20 207c2c27 5c202020 20202020 2c202020 2c27227c 20207c20 207c2020 7c202068 6a770a20 76565c7c 2f76567c 602d275c 20202c2d 2d2d5c20 20207c20 5c56765c 686a7756 765c2f2f 760a2020 20202020 20202020 20205f29 20292020 2020602e 205c202f 0a202020 20202020 20202020 285f5f2f 20202020 20202029 20290a20 20202020 20202020 20202020 20202020 20202020 285f2f"
#endif

#define AK_PROPERTY(type, name, setter, key, initializer) void *key = &key;\
-(type *)name {type *name =  objc_getAssociatedObject (self, key); if (!name) name = initializer(); return name;} \
-(void)setter:(type *)name {objc_setAssociatedObject(self, key, name, OBJC_ASSOCIATION_RETAIN);}

#define iflet(VARIABLE, VALUE) \
ifletwhere(VARIABLE, VALUE, YES)

#define ifletwhere(VARIABLE, VALUE, WHERE) \
for (BOOL b_ = YES; b_ != NO;) \
for (id obj_ = (VALUE); b_ != NO;) \
for (VARIABLE = (obj_ ?: (VALUE)); b_ != NO; b_ = NO) \
if (obj_ != nil && (WHERE))

#pragma mark - Custom Classes -

@interface AKTimer ()
@property NSDate *start;
@property NSMutableDictionary <NSString *, NSNumber *> *values;
//@property NSMutableDictionary <NSString *, NSNumber *> *iterations;
@property NSMutableArray <NSString *> *keys;
@property long printIterations;
@property (readonly) NSString *name;
@end

@implementation AKTimer {
    dispatch_queue_t _que;
}
static NSDate *startDate;
+(void)start {
    startDate = [NSDate date];
}

+(void)log {
    float time = [startDate timeIntervalSinceNow];
    NSLog(@"TIMER <%@>: %f", -time);
    [self start];
}

+(void)logWithString:(NSString *)string {
    float time = [startDate timeIntervalSinceNow];
    NSLog(@"%@: %f", string, -time);
    [self start];
}


+(instancetype)timerNamed:(NSString *)str {
#ifdef DEBUG
    return staticVariableWithID(str, ^id{
        return [[AKTimer alloc] initWithName:str];
    });
#else
    return nil;
#endif
}

+(instancetype)timerStarted {
    AKTimer *timer = [[AKTimer alloc] init];
    [timer reset];
    return timer;
}

- (instancetype)initWithName:(NSString *)name {
    self = [self init];
    if (self) {
        _name = name;
    }
    return self;
}

-(instancetype)init {
    self = [super init];
    if (self) {
        _values = [[NSMutableDictionary alloc] init];
        _keys = [[NSMutableArray alloc] init];
        //        _iterations = [[NSMutableDictionary alloc] init];
        _printIterations = 0;
        _clearOnPrint = YES;
        
        _que = dispatch_queue_create("AKTimer", DISPATCH_QUEUE_CONCURRENT);
        dispatch_set_target_queue(_que, dispatch_get_global_queue(DISPATCH_QUEUE_PRIORITY_HIGH, 0));
    }
    return self;
}

-(void)log:(NSString *)str {
    NSDate *logDate = [NSDate date];
    __block float f;
    dispatch_sync(_que, ^{
        f = [_values valueForKey:str].floatValue;
    });
    
    f += [logDate timeIntervalSinceDate:self.start];
    
    dispatch_barrier_sync(_que, ^{
        [_values setValue:@(f) forKey:str];
        if (![_keys containsObject:str]) {
            [_keys addObject:str];
        }
    });
    [self reset];
}

-(void)print {
    [self printAfterIterations:1];
}

-(void)printAfterIterations:(NSInteger)iterations {
    __block long iter;
    dispatch_barrier_sync(_que, ^{
        iter = ++_printIterations;
    });
    if (iter % iterations) {
        return;
    }
    
    static dispatch_queue_t printQueue;
    static dispatch_once_t onceToken;
    dispatch_once(&onceToken, ^{
        printQueue = dispatch_queue_create("lock", DISPATCH_QUEUE_SERIAL);
    });
    
    dispatch_sync(_que, ^{
        dispatch_sync(printQueue, ^{
            NSLog(@" ");
            NSLog(@" <TIMER name = \"%@\">", _name);
            float sum = 0;
            float iterations = iter;//[[_iterations valueForKey:key] floatValue];;
            for (NSString *key in _keys) {
                float value = [(NSNumber *)[_values valueForKey:key] floatValue];
                sum += value;
                NSLog(@"    %f - %@ ",value/iterations,key);
            }
            if (_keys.count > 1){
                NSLog(@"   --------------");
                NSLog(@"   All: %f (%d iterations)", (sum / (float)iter), (int)iter);
            }
            NSLog(@" </TIMER>");
        });
    });
    
    if (self.clearOnPrint) {
        dispatch_barrier_sync(_que, ^{
            _keys = [[NSMutableArray alloc] init];
            _values = [[NSMutableDictionary alloc] init];
            _printIterations = 0;
        });
    }
}

-(void)reset {
    self.start = [NSDate date];
}

@end

@implementation Geometry {
    CGRect _rect;
}

+(Geometry *(^)(CGSize))size {
    return ^id(CGSize size) {
        Geometry *g = [[Geometry alloc] init];
        g->_rect = CGRectMake(0, 0, size.width, size.height);
        return g;
    };
}

+(Geometry *(^)(CGRect))frame {
    return ^id(CGRect frame) {
        Geometry *g = [[Geometry alloc] init];
        g->_rect = frame;
        return g;
    };
}

+(Geometry *(^)(CGPoint))point {
    return ^id(CGPoint point) {
        Geometry *g = [[Geometry alloc] init];
        g->_rect = CGRectMake(point.x, point.y, 0, 0);
        return g;
    };
}

-(Geometry *(^)(CGRect))centerIn {
    return ^id(CGRect frame) {
        CGFloat x = frame.size.width/2.-_rect.size.width/2. + frame.origin.x;
        CGFloat y = frame.size.height/2.-_rect.size.height/2. + frame.origin.y;
        _rect.origin = CGPointMake(x, y);
        return self;
    };
}

-(Geometry *(^)(CGRect))boundIn {
    return ^id(CGRect frame) {
        if (_rect.origin.x < frame.origin.x) {
            _rect.origin.x = frame.origin.x;
        } else if (_rect.origin.x + _rect.size.width > frame.origin.x + frame.size.width){
            _rect.origin.x = frame.origin.x + frame.size.width - _rect.size.width;
        }
        
        if (_rect.origin.y < frame.origin.y) {
            _rect.origin.y = frame.origin.y;
        } else if (_rect.origin.y + _rect.size.height > frame.origin.y + frame.size.height){
            _rect.origin.y = frame.origin.y + frame.size.height - _rect.size.height;
        }
        return self;
    };
}

-(Geometry *(^)(CGSize))fill {
    return ^id(CGSize sizeToFill) {
        CGSize size = _rect.size;
        float ratio = size.width / size.height;
        CGSize szFill = ratio <  sizeToFill.width / sizeToFill.height ? CGSizeMake(sizeToFill.width, sizeToFill.width / ratio) : CGSizeMake(sizeToFill.height * ratio, sizeToFill.height);
        CGPoint pntFill = CGPointMake(sizeToFill.width/2.-szFill.width/2., sizeToFill.height/2.-szFill.height/2.);
        _rect =  (CGRect){pntFill, szFill}; 
        return self;
    };
}

-(Geometry *(^)(CGSize))fit {
    return ^id(CGSize sizeToFit) {
        CGSize size = _rect.size;
        float ratio = size.width / size.height;
        CGSize szFit = (ratio > sizeToFit.width / sizeToFit.height) ? CGSizeMake(sizeToFit.width, sizeToFit.width / ratio) : CGSizeMake(sizeToFit.height * ratio, sizeToFit.height);
        CGPoint pntFit = CGPointMake(sizeToFit.width/2.-szFit.width/2., sizeToFit.height/2.-szFit.height/2.);
        _rect = (CGRect){pntFit, szFit};
        return self;
    };
}

-(Geometry *(^)(CGFloat))scale {
    return ^id(CGFloat scale) {
        _rect = CGRectMake(_rect.origin.x*scale, _rect.origin.y*scale, _rect.size.width*scale, _rect.size.height*scale);
        return self;
    };
}

-(Geometry *(^)(CGFloat))shift {
    return ^id(CGFloat shift) {
        _rect = CGRectMake(_rect.origin.x+shift, _rect.origin.y+shift, _rect.size.width-shift*2., _rect.size.height-shift*2.);;
        return self;
    };
}

-(Geometry *(^)(CGPoint))move {
    return ^id(CGPoint move) {
        _rect.origin.x += move.x;
        _rect.origin.y += move.y;
        return self;
    };
}
-(Geometry *(^)(void))round {
    return ^id() {
        _rect = CGRectMake(round(_rect.origin.x), round(_rect.origin.y), round(_rect.size.width), round(_rect.size.height));
        return self;
    };
}


-(CGRect)rect {
    return _rect;
}
-(CGRect)frame {
    return _rect;
}
-(CGPoint)point {
    return _rect.origin;
}
-(CGSize)size {
    return _rect.size;
}
-(CGPoint)center{
    return CGPointMake(_rect.origin.x + _rect.size.width/2., _rect.origin.y + _rect.size.height/2.);
}
-(CGFloat)x {
    return _rect.origin.x;
}
-(CGFloat)y {
    return _rect.origin.y;
}
-(CGFloat)width {
    return _rect.size.width;
}
-(CGFloat)height{
    return _rect.size.height;
}
@end

@implementation G: Geometry

@end

@implementation ViewFromXib

- (id)initWithFrame:(CGRect)frame {
    self = [super initWithFrame:frame];
    if (self) {
        [self prepareForNib];
        [self setupCustomView];
        if(CGRectIsEmpty(frame)) {
            self.bounds = _customView.bounds;
        }
    }
    return self;
}

- (id)initWithCoder:(NSCoder *)aDecoder {
    self = [super initWithCoder:aDecoder];
    if(self) {
        [self prepareForNib];
        [self setupCustomView];
    }
    return self;
}

-(void)prepareForNib{
    for (NSView *vi in self.subviews) {
        [vi removeFromSuperview];
    }
}

-(void)setupCustomView {
    NSString *className = NSStringFromClass([self class]);
    NSRange range = [className rangeOfCharacterFromSet:[NSCharacterSet characterSetWithCharactersInString:@"."]];
    if (range.length > 0) {
        className = [className substringFromIndex: range.location + 1];
    }
    NSArray *arr;
    [[NSBundle mainBundle] loadNibNamed:className owner:self topLevelObjects:&arr];
    _customView = arr.firstObject;
    _customView.frame = self.bounds;
    [self addSubview:_customView];
}
-(void)layoutSubtreeIfNeeded {
    [super layoutSubtreeIfNeeded];
    _customView.frame = self.bounds;
}
-(void)layout {
    [super layout];
    _customView.frame = self.bounds;
}
@end

@implementation DragView
{
	bool _mouseIn;
	CGPoint _mousePosition;
	NSInteger _prevSessionNumber;
	bool _performed;
}

- (id)initWithCoder:(NSCoder *)aDecoder {
	if(self = [super initWithCoder:aDecoder]) {
		_strTitle = @"";
		_strDescription = @"";
		self.wantsLayer = YES;
	}
	return self;
}

-(void)drawRect:(NSRect)dirtyRect
{
    if (!_showImage)
        return;
	//frame
    [NSGraphicsContext saveGraphicsState];
	const float delta = 30;
	const CGFloat dash[] = {10, 10};
	NSBezierPath *bpath = [NSBezierPath bezierPath];
	[bpath appendBezierPathWithRoundedRect:NSMakeRect(delta, delta, dirtyRect.size.width-delta*2., dirtyRect.size.height-delta*2.) xRadius:5 yRadius:5];
	[bpath setLineDash:dash count:2 phase:0];
	[bpath setLineWidth:2.];
    if (!_mouseIn) {
		[_lineColor set];
    }
    else {
		[_highlightedColor set];
    }
	[bpath stroke];
    
    if (_showImage == 1) {
        [NSGraphicsContext restoreGraphicsState];
        return;
    }
	//text 1 (prepare)
	float fontSize = MIN(25,MIN(dirtyRect.size.height/20., dirtyRect.size.width/25.));
	NSMutableParagraphStyle *paragraphStyle = [NSMutableParagraphStyle new];
	paragraphStyle.alignment = NSTextAlignmentCenter;
    NSColor * labelColor = [NSColor colorWithWhite:.4 alpha:1];
    
	NSFont * labelFont = [NSFont systemFontOfSize:fontSize weight:NSFontWeightLight];
	NSDictionary *attrs =  @{NSParagraphStyleAttributeName : paragraphStyle, NSFontAttributeName : labelFont , NSForegroundColorAttributeName : labelColor};
	NSAttributedString *title = [[NSAttributedString alloc] initWithString : _strTitle attributes : attrs];
    
    NSFont * dscrFont = [NSFont systemFontOfSize:fontSize*0.8 weight:NSFontWeightLight];
	NSDictionary *attrs1 =  @{NSParagraphStyleAttributeName : paragraphStyle, NSFontAttributeName : dscrFont, NSForegroundColorAttributeName : labelColor};
	NSAttributedString *description = [[NSAttributedString alloc] initWithString : _strDescription attributes : attrs1];
    
	float textDelta = title.size.height + description.size.height/2.;
	CGSize drawSize = CGSizeMake(dirtyRect.size.width*.6 - delta, dirtyRect.size.height*.6 - delta);
    
    const CGSize sz = _image.size;
    drawSize = G.size(sz).fit(drawSize).size;
    if (sz.width < drawSize.width)
        drawSize = sz;

    //picture
    if (!_progressMode) {
        CGPoint drawPoint = CGPointMake(dirtyRect.size.width/2.-drawSize.width/2., dirtyRect.size.height/2.-drawSize.height/2.+textDelta);
        if (CGSizeEqualToSize(drawSize, sz) )
            CGContextSetInterpolationQuality([NSGraphicsContext currentContext].CGContext, kCGInterpolationNone);
        else
            CGContextSetInterpolationQuality([NSGraphicsContext currentContext].CGContext, kCGInterpolationMedium);
        [_image drawInRect:CGRectMake(drawPoint.x, drawPoint.y, drawSize.width, drawSize.height)];
		
    }
    else {
        float angle = (1 - _progress)*180.;
        CGPoint drawPoint = CGPointMake(dirtyRect.size.width/2., dirtyRect.size.height/2.-drawSize.height/2.+textDelta);
        
        [[NSColor r:0.2 g:0.9 b:0.2] setFill];
        [[NSBezierPath bezierPathWithArcInCenter:drawPoint radius:drawSize.width/2. fromAngle:angle to:180] fill];
        
        NSBezierPath *pth = [NSBezierPath bezierPathWithArcInCenter:drawPoint radius:drawSize.width/2. fromAngle:0 to:180];
        pth.lineWidth = 2;
        [[labelColor colorWithAlphaComponent:.4] setStroke];
        [pth stroke];
    }
    
    //text 2 (draw)
	[title drawInRect:NSMakeRect(0, 0, dirtyRect.size.width, dirtyRect.size.height/2.-drawSize.height/2.+textDelta*0.5)];
	[description drawInRect:NSMakeRect(0, 0, dirtyRect.size.width, dirtyRect.size.height/2.-drawSize.height/2.-textDelta*0.5)];
    
    if (_strInfoText)
    {
        NSDictionary *attrs2 =  @{ NSFontAttributeName : dscrFont , NSForegroundColorAttributeName : labelColor };
        NSAttributedString *info = [[NSAttributedString alloc] initWithString : _strInfoText attributes : attrs2];
        [info drawInRect:NSMakeRect(delta + 17, 0, dirtyRect.size.width, dirtyRect.size.height - delta - 10)];
    }
    [NSGraphicsContext restoreGraphicsState];
}

-(void)setStrDescription:(NSString *)strDescription
{
	_strDescription = strDescription;
	[self setNeedsDisplay:YES];
}
-(void)setStrTitle:(NSString *)strTitle
{
	_strTitle = strTitle;
	[self setNeedsDisplay:YES];
}
//-(void)mouseDown:(NSEvent *)theEvent
//{
//}

-(void)viewDidMoveToWindow
{
	[self registerForDraggedTypes:[NSArray arrayWithObjects:NSFilesPromisePboardType, NSFilenamesPboardType, nil]];
}

-(NSDragOperation)draggingEntered:(id <NSDraggingInfo>)sender
{
	_performed = NO;
	_mouseIn = YES;
	[self setNeedsDisplay:YES];
	return NSDragOperationCopy;
}
-(void)draggingExited:(id<NSDraggingInfo>)sender
{
	_mouseIn = NO;
	if ([_delegate respondsToSelector:@selector(dragViewExited:)])
		[_delegate dragViewExited:self];
	[self setNeedsDisplay:YES];
}
-(BOOL) prepareForDragOperation:(id<NSDraggingInfo>)sender
{
	return YES;
}

- (BOOL)performDragOperation:(id <NSDraggingInfo>)sender
{
	_performed = YES;
	_mouseIn = NO;
	[self setNeedsDisplay:YES];
    NSMutableArray *urls = [NSMutableArray new];
    
    
    NSPasteboard * paste = [sender draggingPasteboard];
    NSArray * types = [NSArray arrayWithObjects: NSFilenamesPboardType, nil];
    NSString * desiredType = [paste availableTypeFromArray:types];
    if ([desiredType isEqualToString : NSFilenamesPboardType])
        [urls addObjectsFromArray:[paste readObjectsForClasses:@[[NSURL class]] options:nil]];
    if (urls.count) {
		[_delegate dragView:self filesComplete:urls needsWait:NO];
        return YES;
    }
    else {
        NSURL *dropLocation = [[NSFileManager defaultManager] URLsForDirectory:NSCachesDirectory inDomains:NSUserDomainMask].firstObject;
        NSArray *filenames = [sender namesOfPromisedFilesDroppedAtDestination:dropLocation];
        if (filenames.count)
        {
            for (NSString *str in filenames) {
                NSURL *url = [dropLocation URLByAppendingPathComponent:str];
                [urls addObject:url];
            }
            if (urls.count) {
				[_delegate dragView:self filesComplete:urls needsWait:YES];
                return YES;
            }
        }
    }
	[_delegate dragView:self filesComplete:@[] needsWait:NO];
	return NO;
}

- (void)draggingEnded:(id <NSDraggingInfo>)sender {
	if (!_performed)
	{
		if ([_delegate respondsToSelector:@selector(dragViewCancelled:)])
			[_delegate dragViewCancelled:self];
	}
}

//-(void)concludeDragOperation:(id<NSDraggingInfo>)sender
//{
//	NSLog(@"conclude! %d",_mouseIn);
//}

-(NSDragOperation)draggingUpdated:(id<NSDraggingInfo>)sender
{

	CGPoint datPos = [NSEvent mouseLocation];
	NSInteger sequence = sender.draggingSequenceNumber;
	bool newSession = sequence != _prevSessionNumber;
	if (!CGPointEqualToPoint(datPos, _mousePosition) || newSession)
	{
		_mousePosition = datPos;
		_prevSessionNumber = sequence;
		NSArray *urls = [[sender draggingPasteboard] readObjectsForClasses:@[[NSURL class]] options:nil];
		if ([_delegate respondsToSelector:@selector(dragView:filesPerform:newSession:)])
			[_delegate dragView:self filesPerform:urls newSession:newSession];
	}
	return NSDragOperationCopy;
}

-(void)setProgressMode:(bool)progressMode
{
    _progressMode = progressMode;
    [self setNeedsDisplay:YES];
}
-(void)setStrInfoText:(NSString *)strInfoText
{
    _strInfoText = strInfoText;
    [self setNeedsDisplay:YES];
}
-(void)setProgress:(float)progress
{
    _progress = progress;
    [self setNeedsDisplay:YES];
}
-(void)setHideAll:(bool)hideAll
{
	_showImage = hideAll;
	[self setNeedsDisplay:YES];
}
@end

@implementation ColorableView {
	BOOL _draw;
}

-(instancetype)initWithFrame:(NSRect)frameRect {
	self = [super initWithFrame:frameRect];
    _draw = YES;
	return self;
}

-(instancetype)initWithCoder:(NSCoder *)decoder {
    if (self = [super initWithCoder:decoder]) {
        _draw = YES;
    }
    return self;
}

-(void)drawRect:(NSRect)dirtyRect
{
	if (_draw) {
//        [NSGraphicsContext saveGraphicsState];
		[_backgroundColor set];
        NSRectFill(dirtyRect);
//        [NSGraphicsContext restoreGraphicsState];
	}
}
-(void)setBackgroundColor:(NSColor *)backgroundColor{
    _backgroundColor = backgroundColor;
    [self setNeedsDisplay:YES];
}

-(void)prepareForInterfaceBuilder {
	_draw = YES;
}
@end


@implementation GradientView
-(instancetype)initWithFrame:(NSRect)frameRect {
	self = [super initWithFrame:frameRect];
	return self;
}

-(void)drawRect:(NSRect)dirtyRect {
	[NSGraphicsContext saveGraphicsState];
	NSGradient *grad = [[NSGradient alloc] initWithColors:@[_bottomColor,_topColor]];
	[grad drawInRect:CGRectMake(dirtyRect.origin.x, self.bounds.origin.y, dirtyRect.size.width, self.bounds.size.height) angle:90];
	[NSGraphicsContext restoreGraphicsState];
}
@end

@implementation GradientButton
{
	bool mouseIsDown;
}
-(instancetype)initWithCoder:(NSCoder *)coder
{
	if (self = [super initWithCoder:coder])
	{
		[self init2];
	}
	return self;
}

-(void)init2
{
	_textColor = [NSColor whiteColor];
	_activeColor = [NSColor r:53 g:125 b:210];
	//_activeGradient = [NSColor r:36 g:80 b:147];
	_pressedColor = [NSColor r:36 g:80 b:147];
	//_pressedGradient = [NSColor r:20 g:50 b:100];
	_borderColor = [NSColor r:31 g:74 b:122];
}

-(void)drawRect:(NSRect)dirtyRect
{
    float delta = 1;
    NSBezierPath *bpath = [NSBezierPath bezierPath];
    [bpath appendBezierPathWithRoundedRect:NSMakeRect(delta, delta, dirtyRect.size.width - delta * 2., dirtyRect.size.height - delta * 2.) xRadius:4 yRadius:4];
    
    [NSGraphicsContext saveGraphicsState];
	[_borderColor set];
	[bpath setLineWidth:2.];
	[bpath stroke];

	if (!mouseIsDown) 
		[[[NSGradient alloc] initWithStartingColor: _activeColor endingColor: _activeGradient ? _activeGradient : _activeColor] drawInBezierPath:bpath angle:90];
	else
		[[[NSGradient alloc] initWithStartingColor: _pressedColor endingColor: _pressedGradient ? _pressedGradient: _pressedColor] drawInBezierPath:bpath angle:90];
	NSDictionary *attrsDictionary = [NSDictionary dictionaryWithObjectsAndKeys: self.font, NSFontAttributeName, _textColor, NSForegroundColorAttributeName, nil];
	CGSize sz = [[self title] sizeWithAttributes:attrsDictionary];
	[[self title] drawAtPoint:NSMakePoint(dirtyRect.size.width/2.-sz.width/2., dirtyRect.size.height/2.-sz.height/2.-2) withAttributes:attrsDictionary];
    [NSGraphicsContext restoreGraphicsState];
}

-(void)setTitleColor:(NSColor *)clr
{
	_textColor = clr;
}

- (void)mouseDown:(NSEvent *)theEvent {
	mouseIsDown = YES;
	[self setNeedsDisplay:YES];
	[super mouseDown:theEvent];
	mouseIsDown = NO;
	[self setNeedsDisplay:YES];
    
    return;
    //event loop
}

@end

@interface ThreadFlow ()
@property long counter;
@property NSDate *lastDispatch;
@end

@implementation ThreadFlow

-(id)initWithName:(NSString *)name
{
    self = [super init];
    if (self) {
        _counter = 0;
        _name = name;
    }
    return self;
}



+(ThreadFlow *)flowNamed:(NSString *)str
{
    static NSMutableDictionary *allFlows;
    static dispatch_queue_t queue;
    
    static dispatch_once_t onceToken;
    dispatch_once(&onceToken, ^{
        allFlows = [NSMutableDictionary new];
        queue = dispatch_queue_create("flowNamed:", DISPATCH_QUEUE_CONCURRENT);
        dispatch_set_target_queue(queue, dispatch_get_global_queue(DISPATCH_QUEUE_PRIORITY_HIGH, 0));
    });
    
    __block ThreadFlow *flow;
    dispatch_sync(queue, ^{
        flow = [allFlows objectForKey:str];
    });
    if (!flow) {
        dispatch_barrier_sync(queue, ^{
            flow = [[ThreadFlow alloc] initWithName:str];
            [allFlows setObject:flow forKey:str];
        });
    }
    return flow;
}

-(void)dispatchAfter:(float)sec block:(dispatch_block_t)block
{
    @synchronized (self) {
        _counter++;
    }
    dispatch_after(dispatch_time(DISPATCH_TIME_NOW, (int64_t)((sec - 0.08)* NSEC_PER_SEC)), dispatch_get_global_queue(DISPATCH_QUEUE_PRIORITY_BACKGROUND, 0), ^{
        long i;
        @synchronized (self) {
            i = --_counter;
        }
        if (!i && block) {
            dispatch_async(dispatch_get_main_queue(), block);
        }
    });
}

-(void)dispatchPeriodicallyAfter:(float)sec block:(dispatch_block_t)block
{

    @synchronized (self) {
        if (!_lastDispatch) {
            _lastDispatch = [NSDate date];
        }
        _counter++;
    }
    dispatch_after(dispatch_time(DISPATCH_TIME_NOW, (int64_t)((sec - 0.08)* NSEC_PER_SEC)), dispatch_get_global_queue(DISPATCH_QUEUE_PRIORITY_BACKGROUND, 0), ^{
        long i;
        @synchronized (self) {
            i = --_counter;
            if ([_lastDispatch timeIntervalSinceNow] < -sec) {
                _lastDispatch = nil;
                i = 0;
            }
        }
        if (!i && block) {
            dispatch_async(dispatch_get_main_queue(), block);
        }
    });
}

@end

@implementation ClickableTextFied
-(NSView *)hitTest:(NSPoint)aPoint {
    return nil;
}
@end

@implementation AKMonitor
{
    BOOL _alt;
    BOOL _ctrl;
    BOOL _cmnd;
    BOOL _shift;
}
-(instancetype)init
{
    [NSEvent addLocalMonitorForEventsMatchingMask : NSFlagsChangedMask
                                          handler : ^NSEvent * (NSEvent * theEvent)
     {
         if (theEvent.modifierFlags & NSEventModifierFlagOption)
             _alt = YES;
         else
             _alt = NO;
         
         if (theEvent.modifierFlags & NSEventModifierFlagControl)
             _ctrl = YES;
         else
             _ctrl = NO;
         
         if (theEvent.modifierFlags & NSEventModifierFlagCommand)
             _cmnd = YES;
         else
             _cmnd = NO;
         
         if (theEvent.modifierFlags & NSEventModifierFlagShift)
             _shift = YES;
         else
             _shift = NO;
         
         return theEvent;
     }];
    return self;
}

static AKMonitor *monik;
+(void)load {
    monik = [[AKMonitor alloc] init];
}
+(BOOL)altPressed
{
    BOOL n = monik->_alt;
    return n;
}

+(BOOL)cmndPressed
{
    BOOL n = monik->_cmnd;
    return n;
}

+(BOOL)ctrlPressed
{
    BOOL n = monik->_ctrl;
    return n;
}
+(BOOL)shiftPressed
{
    BOOL n = monik->_shift;
    return n;
}
@end


#pragma mark - Native Classes

#pragma mark - NSEvent
@implementation NSEvent (event)
-(CGPoint)locationInView:(NSView *)vi
{
	if (vi.window == self.window)
		return [self.window.contentViewController.view convertPoint:self.locationInWindow toView:vi];
	return CGPointZero;
}
@end

#pragma mark - NSView
@interface AKBlocker : NSView
@property NSProgressIndicator *prog;
-(void)block:(NSString *)string;
-(void)unblock:(NSString *)string;
@end

@implementation AKBlocker {
	NSMutableArray <NSString *> *_blockers;
}

-(instancetype)init {
	self = [super init];
	_blockers = [NSMutableArray new];
	_prog = [NSProgressIndicator new];
	_prog.style = NSProgressIndicatorSpinningStyle;
	[_prog startAnimation:nil];
	[self addSubview:_prog];
	return self;
}

-(void)viewDidMoveToSuperview {
	self.frame = self.superview.bounds;
	_prog.frame = self.frame;
	[self setAutoresizingMask:NSViewWidthSizable | NSViewHeightSizable];
	[_prog setAutoresizingMask:NSViewWidthSizable | NSViewHeightSizable];
}

-(void)block:(NSString *)string {
    for (NSString *s in _blockers) {
        if ([s isEqualToString:string]) {
			return;
        }
    }
	[_blockers addObject:string];
}

-(void)unblock:(NSString *)string {
    for (long i = _blockers.count; i--; ) {
        if ([_blockers[i] isEqualToString: string]) {
            [_blockers removeObjectAtIndex:i];
        }
    }
    
    if (!_blockers.count) {
        [self removeFromSuperview];
    }
}

-(void)rightMouseDown:(NSEvent *)event { }
-(void)rightMouseDragged:(NSEvent *)event { }
-(void)rightMouseUp:(NSEvent *)event { }
-(void)scrollWheel:(NSEvent *)event { }
-(void)mouseDown:(NSEvent *)theEvent { }
-(void)mouseDragged:(NSEvent *)theEvent { }
-(void)mouseUp:(NSEvent *)theEvent { }
@end

@implementation NSView (ActionBlock)
- (NSArray*) allSubviews {
	__block NSArray* allSubviews = [NSArray arrayWithObject:self];
	[self.subviews enumerateObjectsUsingBlock:^( NSView* view, NSUInteger idx, BOOL*stop) {
		allSubviews = [allSubviews arrayByAddingObjectsFromArray:[view allSubviews]];
	}];
	return allSubviews;
}

-(void)setMaskWithCornerRadius:(int)rad
{
	self.wantsLayer = YES;
	CALayer *mask = [CALayer new];
	mask.frame = self.bounds;
	DrawRectRounded(mask, self.bounds, [NSColor whiteColor], [NSColor clearColor], 0, rad);
	[self.layer setMask:mask];
}

- (NSImage *)imageRepresentation:(CGInterpolationQuality)qual
{
	self.wantsLayer = YES;
	NSImage *image = [[NSImage alloc] initWithSize:G.frame(self.bounds).round().size];
	[image lockFocus];
	CGContextRef ctx = [NSGraphicsContext currentContext].CGContext;
	CGContextSetInterpolationQuality(ctx, qual);
	[self.layer renderInContext: ctx];
	[image unlockFocus];
	return image;
}


-(NSImage *)imageRepresentationWindowScreenshot
{
	if (!self.window)
		return nil;
	[self lockFocus];
	NSBitmapImageRep *bitmap = [[NSBitmapImageRep alloc] initWithFocusedViewRect:[self bounds]];
	[self unlockFocus];
	NSImage *image = [[NSImage alloc] initWithSize:[self bounds].size];
	[image addRepresentation:bitmap];
	return image;
}
-(void) removeAllSubviews
{
    for (NSView *view in [self.subviews reverseObjectEnumerator]) {
		[view removeFromSuperview];
    }
}
-(void) layerBackground:(NSColor *)color
{
	self.wantsLayer = YES;
	self.layer.backgroundColor = [color CGColor];
}

-(CGPoint) pointInFrame:(CGPoint) abscoord
{
	CGPoint p = abscoord;
	NSView *parView = (NSView *)self;
	while(parView.window==nil)
	{
		p.x -= parView.superview.frame.origin.x;
		p.y -= parView.superview.frame.origin.y;
		parView = parView.superview;
	}
	return p;
}

-(CGPoint) coordInFrame:(CGPoint) abscoord
{
	NSRect frameRelativeToWindow = [self convertRect: self.bounds toView: nil];
	CGPoint coord = abscoord;
	coord.x -= frameRelativeToWindow.origin.x;
	coord.y -= frameRelativeToWindow.origin.y;
	return coord;
}

- (void)setBackgroundColor: (NSColor *)color
{
	CALayer *viewLayer = [CALayer layer];
	BOOL swl = self.wantsLayer;
	[viewLayer setBackgroundColor: color.CGColor];
	[self setWantsLayer:YES];
	[self setLayer: viewLayer];
	[self setWantsLayer:swl];
}

- (NSImage *)imageRepresentation
{
	self.wantsLayer = YES;
	NSImage *image = [[NSImage alloc] initWithSize:G.frame(self.bounds).round().size];
	[image lockFocus];
	CGContextRef ctx = [NSGraphicsContext currentContext].CGContext;
	[self.layer renderInContext: ctx];
	[image unlockFocus];
	return image;
}

- (NSImage *)imageRepresentationOld {
	NSBitmapImageRep* rep = [self bitmapImageRepForCachingDisplayInRect:G.frame(self.bounds).round().rect];
	[self cacheDisplayInRect:G.frame(self.bounds).round().rect toBitmapImageRep:rep];
	NSImage *image = [[NSImage alloc]initWithSize: G.frame(self.bounds).round().size];
	[image addRepresentation:rep];
	return image;
}
-(void)lockMouse
{
    if (!([NSEvent pressedMouseButtons] & NSEventTypeLeftMouseDown))
        return;
    BOOL keepOn = YES;
    while (keepOn) {
        NSEvent *theEvent = [[self window] nextEventMatchingMask: NSLeftMouseUpMask | NSLeftMouseDraggedMask | NSScrollWheelMask | NSKeyDownMask];
        switch ([theEvent type]) {
            case NSLeftMouseDragged:
                [self mouseDragged:theEvent];
                break;
            case NSLeftMouseUp:
                [self mouseUp:theEvent];
                keepOn = NO;
                break;
            default:
                break;
        }
    };
}
-(CALayer *)setImageLayer:(NSImage*)img
{
	self.wantsLayer = YES;
	[self.layer removeAllSublayers];
	if (!img)
		return nil;
	CALayer *imgLayer = [CALayer new];
	imgLayer.frame = self.bounds;
	imgLayer.contents = img;
	imgLayer.contentsGravity = @"resizeAspectFill";
	[self.layer addSublayer:imgLayer];
	imgLayer.autoresizingMask = kCALayerWidthSizable | kCALayerHeightSizable;
	return imgLayer;
}

-(AKBlocker *)blocker {
    __block AKBlocker *blocker;
    [self.subviews enumerateObjectsUsingBlock:^(__kindof NSView * _Nonnull obj, NSUInteger idx, BOOL * _Nonnull stop) {
        if ([obj isKindOfClass:[AKBlocker class]]) {
            blocker = obj;
            *stop = YES;
        }
    }];
    return blocker;
}

-(void)blockWithoutProgress:(NSString *)blockerName {
    [self blockWithCircular: blockerName];
    AKBlocker *blocker = [self blocker];
    [blocker.prog removeFromSuperview];
}

-(void)blockWithCircular:(NSString *)blockerName  {
    AKBlocker *blocker = [self blocker];
    if (!blocker) {
        blocker = [[AKBlocker alloc] init];
        [self addSubview:blocker];
    }
    [blocker block:blockerName];
}

-(void)unblock:(NSString *)blockerName
{
	AKBlocker *blocker;
	for (NSView *v in self.subviews)
	{
		if ([v isKindOfClass:[AKBlocker class]])
		{
			blocker = (AKBlocker *) v;
			break;
		}
	}
    if (blocker) {
		[blocker unblock:blockerName];
    }
}

- (void)removeADsScaleAnimation {
    double duration = 1;
    double scaleValue = 1.1;
    
    NSMutableArray<CAAnimation *> *animations = [NSMutableArray new];
    
    CAKeyframeAnimation *scale = [CAKeyframeAnimation animationWithKeyPath:@"transform.scale"];
    scale.timingFunction = [CAMediaTimingFunction functionWithName:kCAMediaTimingFunctionEaseInEaseOut];
    scale.values = @[@1, @(scaleValue), @1];
    scale.repeatCount = 1;
    scale.duration = duration;
    [animations addObject:scale];
    
    CAKeyframeAnimation *scaleX = [CAKeyframeAnimation animationWithKeyPath:@"transform.translation.x"];
    scaleX.timingFunction = [CAMediaTimingFunction functionWithName:kCAMediaTimingFunctionEaseInEaseOut];
    scaleX.values = @[@0, @(self.frame.size.width/2.*(1-scaleValue)), @0];
    scaleX.repeatCount = 1;
    scaleX.duration = duration;
    [animations addObject:scaleX];
    
    CAKeyframeAnimation *scaleY = [CAKeyframeAnimation animationWithKeyPath:@"transform.translation.y"];
    scaleY.timingFunction = [CAMediaTimingFunction functionWithName:kCAMediaTimingFunctionEaseInEaseOut];
    scaleY.values = @[@0, @(self.frame.size.height/2.*(1-scaleValue)), @0];
    scaleY.repeatCount = 1;
    scaleY.duration = duration;
    [animations addObject:scaleY];
    
    CAAnimationGroup *group = [CAAnimationGroup animation];
    group.duration = duration;
    group.repeatCount = INFINITY;
    group.animations = animations;
    
    [self.layer addAnimation:group forKey:@"5465465768678678654646987"];
}
@end

#pragma mark - NSBezierPath
@implementation NSBezierPath (BezierPathUtilities)
+ (NSBezierPath *)bezierPathWithArcInCenter:(NSPoint)centerPoint radius:(float)radius fromAngle:(float)angle1 to:(float)angle2
{
    float radius2 = radius/2.;
    NSBezierPath *thePath = [NSBezierPath new];
//    [thePath moveToPoint:CG];
    [thePath appendBezierPathWithArcWithCenter:centerPoint radius:radius startAngle:angle1 endAngle:angle2];
    [thePath appendBezierPathWithArcWithCenter:centerPoint radius:radius2 startAngle:angle2 endAngle:angle1 clockwise:YES];
    [thePath closePath];
    return thePath;
}
- (void)strokeInside
{
	/* Stroke within path using no additional clipping rectangle. */
	[self strokeInsideWithinRect:NSZeroRect];
}

- (void)strokeInsideWithinRect:(NSRect)clipRect
{
	float lineWidth = [self lineWidth];
	[[NSGraphicsContext currentContext] saveGraphicsState];
	[self setLineWidth:(lineWidth * 2.0)];
	[self setClip];

	/* Further clip drawing to clipRect, usually the view's frame. */
	if (clipRect.size.width > 0.0 && clipRect.size.height > 0.0) {
		[NSBezierPath clipRect:clipRect];
	}

	/* Stroke the path. */
	[self stroke];

	/* Restore the previous graphics context. */
	[[NSGraphicsContext currentContext] restoreGraphicsState];
	[self setLineWidth:lineWidth];
}

- (CGPathRef)quartzPathWithSize:(CGSize)sz
{
    long i, numElements;
    
    // Need to begin a path here.
    CGPathRef immutablePath = NULL;
    
    // Then draw the path elements.
    numElements = [self elementCount];
    if (numElements > 0)
    {
        CGMutablePathRef path = CGPathCreateMutable();
        NSPoint points[3];
        BOOL didClosePath = YES;
        float scaleX = sz.width;
        float scaleY = sz.height;
        for (i = 0; i < numElements; i++)
        {
            switch ([self elementAtIndex:i associatedPoints:points])
            {
                case NSMoveToBezierPathElement:
                    CGPathMoveToPoint(path, NULL, points[0].x*scaleX, points[0].y*scaleY);
                    break;
                    
                case NSLineToBezierPathElement:
                    CGPathAddLineToPoint(path, NULL, points[0].x*scaleX, points[0].y*scaleY);
                    didClosePath = NO;
                    break;
                    
                case NSCurveToBezierPathElement:
                    CGPathAddCurveToPoint(path, NULL, points[0].x*scaleX, points[0].y*scaleY,
                                          points[1].x*scaleX, points[1].y*scaleY,
                                          points[2].x*scaleX, points[2].y*scaleY);
                    didClosePath = NO;
                    break;
                    
                case NSClosePathBezierPathElement:
                    CGPathCloseSubpath(path);
                    didClosePath = YES;
                    break;
            }
        }
        
        if (!didClosePath)
            CGPathCloseSubpath(path);
        
        immutablePath = CGPathCreateCopy(path);
        CGPathRelease(path);
    }
    
    return immutablePath;
}
// This method works only in OS X v10.2 and later.
- (CGPathRef)quartzPath
{
	long numElements;

	// Need to begin a path here.
	CGPathRef           immutablePath = NULL;

	// Then draw the path elements.
	numElements = [self elementCount];
	if (numElements > 0)
	{
		CGMutablePathRef    path = CGPathCreateMutable();
		NSPoint             points[3];
		BOOL                didClosePath = YES;

		for(int i = 0; i < numElements;i++)
		{
			switch ([self elementAtIndex:i associatedPoints:points])
			{
				case NSMoveToBezierPathElement:
					CGPathMoveToPoint(path, NULL, points[0].x, points[0].y);
					break;

				case NSLineToBezierPathElement:
					CGPathAddLineToPoint(path, NULL, points[0].x, points[0].y);
					didClosePath = NO;
					break;

				case NSCurveToBezierPathElement:
					CGPathAddCurveToPoint(path, NULL, points[0].x, points[0].y,
										  points[1].x, points[1].y,
										  points[2].x, points[2].y);
					didClosePath = NO;
					break;

				case NSClosePathBezierPathElement:
					CGPathCloseSubpath(path);
					didClosePath = YES;
					break;
			}
		}

		// Be sure the path is closed or Quartz may not do valid hit detection.
		if (!didClosePath)
			CGPathCloseSubpath(path);

		immutablePath = CGPathCreateCopy(path);
		CGPathRelease(path);
	}

	return immutablePath;
}
@end


#pragma mark - NSImage

@implementation NSImage (action)

+(NSImage*)imageFromCGImageRef:(CGImageRef)image
{
	NSRect imageRect = NSMakeRect(0.0, 0.0, 0.0, 0.0);
	CGContextRef imageContext = nil;
	NSImage* newImage = nil;
	imageRect.size.height = CGImageGetHeight(image);
	imageRect.size.width = CGImageGetWidth(image);
	newImage = [[NSImage alloc] initWithSize:imageRect.size];
	[newImage lockFocus];
	imageContext = (CGContextRef)[[NSGraphicsContext currentContext] graphicsPort];
	CGContextDrawImage(imageContext, imageRect, image);
	[newImage unlockFocus];

	return newImage;
}
+ (NSImage *)imageWithCIImage:(CIImage *)img
{
	NSCIImageRep *rep = [NSCIImageRep imageRepWithCIImage:img];
	NSImage *nsImage = [[NSImage alloc] initWithSize:img.extent.size];
	[nsImage addRepresentation:rep];
	NSImage *rendered = [[NSImage alloc] initWithSize:img.extent.size];
	[rendered lockFocus];
	[nsImage drawInRect:CGRectMake(0, 0, img.extent.size.width, img.extent.size.height)];
	[rendered unlockFocus];
	return rendered;
}

+ (NSImage *)imageFromURL:(NSURL *)url async:(bool)async
{
	NSImage *img = [self imageFromURL:url];
	if (!async)
		return img;
	int iteration = 0;
	while (!img && iteration < 10)
	{
		unsigned int t = arc4random_uniform(100000)+50000;
		usleep(t);
		img = [NSImage imageFromURL:url];
		iteration++;
	}
	return img;
}

+ (NSImage *)imageFromURL:(NSURL *)url {
	NSArray * imageReps = [NSBitmapImageRep imageRepsWithContentsOfURL:url];
	if (!imageReps.count)
		return nil;
	NSInteger width = 0;
	NSInteger height = 0;
	for (NSImageRep * imageRep in imageReps) {
		width = MAX(width, [imageRep pixelsWide]);
		height = MAX(height, [imageRep pixelsHigh]);
	}
	if (width == 0 || height == 0)
		return nil;
	NSImage *nsImg = [[NSImage alloc] initWithSize:CGSizeMake(width, height)];
	[nsImg addRepresentations:imageReps];
	return nsImg;
}
void *drawKey = &drawKey;
-(void)redraw {
    if (objc_getAssociatedObject(self, drawKey) != nil) {
        return;
    }
    objc_setAssociatedObject(self, drawKey, @(YES), OBJC_ASSOCIATION_RETAIN);
    
    [self lockFocus];
    [self drawInRect:CGRectMake(0, 0, self.size.width, self.size.height)];
    [self unlockFocus];
}

- (NSImage *)resize:(NSSize)newSize {
    NSImage *sourceImage = [self copy];
    
    NSImage *newImage = [[NSImage alloc] initWithSize: newSize];
    [newImage lockFocus];
    [[NSGraphicsContext currentContext] setImageInterpolation:NSImageInterpolationHigh];
    [sourceImage drawInRect:CGRectMake(0, 0, roundf(newSize.width), roundf(newSize.height)) fromRect:CGRectMake(0, 0, sourceImage.size.width, sourceImage.size.height)  operation:NSCompositeCopy fraction:1];
    [newImage unlockFocus];
    return newImage;
	
}

- (NSImage *)crop:(CGRect)newRect {
	NSImage *sourceImage = [self copy];
	// Report an error if the source isn't a valid image
	if (![sourceImage isValid]){
		NSLog(@"Invalid Image");
	} else {
		NSImage *smallImage = [[NSImage alloc] initWithSize: newRect.size];
		[smallImage lockFocus];
		//        [sourceImage setSize: newSize];
		[[NSGraphicsContext currentContext] setImageInterpolation:NSImageInterpolationHigh];
		[sourceImage drawAtPoint:NSZeroPoint fromRect:CGRectMake(roundf(newRect.origin.x), roundf(newRect.origin.y), roundf(newRect.size.width), roundf(newRect.size.height)) operation:NSCompositeCopy fraction:1.0];
		[smallImage unlockFocus];
		return smallImage;
	}
	return nil;
}

-(NSImage *)cropToFill:(CGSize)newSize cornerRadius:(float)radius {
    NSImage *sourceImage = [self copy];
    if (![sourceImage isValid]){
        NSLog(@"Invalid Image");
    } else {
        CGSize resized = G.size(sourceImage.size).fill(newSize).round().size;
        CGRect cropped = G.size(newSize).fit(resized).round().rect;
        
        NSImage *smallImage = [[NSImage alloc] initWithSize: cropped.size];
        
        [smallImage lockFocus];
		if (radius)
		{
			NSBezierPath *path = [NSBezierPath bezierPathWithRoundedRect:CGRectMake(0, 0, newSize.width, newSize.height) xRadius:radius yRadius:radius];
			[path setClip];
		}
        [sourceImage setSize: resized];
        [[NSGraphicsContext currentContext] setImageInterpolation:NSImageInterpolationHigh];
        [sourceImage drawAtPoint:NSZeroPoint fromRect:CGRectMake(cropped.origin.x, cropped.origin.y, newSize.width, newSize.height) operation:NSCompositeCopy fraction:1.0];
        [smallImage unlockFocus];
        return smallImage;
    }
    return nil;
}

- (NSImage *)flipHorisontal:(bool)horiz {
	NSImage *sourceImage = [self copy];
	// Report an error if the source isn't a valid image
	if (![sourceImage isValid]){
		NSLog(@"Invalid Image");
	} else {
		NSImage *img = [[NSImage alloc] initWithSize: [self size]];
		[img lockFocus];
		NSAffineTransform* t = [NSAffineTransform transform];

		if (horiz)
		{
			[t translateXBy:[self size].width yBy:0];
			[t scaleXBy:-1 yBy:1];
		}
		else
		{
			[t translateXBy:0 yBy:[self size].height];
			[t scaleXBy:1 yBy:-1];
		}
		[t concat];
		[sourceImage drawInRect:NSMakeRect(0, 0, [self size].width, [self size].height)];
		[img unlockFocus];
		return img;
	}
	return nil;
}
-(NSData *)compressedJPEGData:(float)factor
{
	NSData *TIFFRep = [self TIFFRepresentation];
	NSBitmapImageRep *imageRep = [[NSBitmapImageRep alloc] initWithData:TIFFRep];
	NSDictionary *options = [NSDictionary dictionaryWithObject:[NSNumber numberWithFloat:factor] forKey:NSImageCompressionFactor];
	return [imageRep representationUsingType:NSJPEGFileType properties:options];

}
-(NSData *)PNGRepresentation
{
	return [[[NSBitmapImageRep alloc] initWithData:[self TIFFRepresentation]] representationUsingType:NSPNGFileType properties:@{}];
}

-(CIImage *) CIImage
{
	NSData *data = [self TIFFRepresentation];
	return [CIImage imageWithData:data];
}

-(CGImageRef) CGImage
{
	CGImageSourceRef source = CGImageSourceCreateWithData((CFDataRef)[self TIFFRepresentation], NULL);
	return CGImageSourceCreateImageAtIndex(source, 0, NULL);
}
-(NSImage *)filterNumber:(long)i
{
    return [NSImage imageWithCIImage:[[self CIImage] filterNumber:(int)i]];
}
-(NSImage *)imageWithCIFilter:(CIFilter *)filter
{
	[filter setValue:[self CIImage] forKey:kCIInputImageKey];
	return [NSImage imageWithCIImage:filter.outputImage];
}
@end


#pragma mark - NSColor
@implementation NSColor (costelique)

float rClr(){
	return arc4random_uniform(256)/255.;
}
+ (NSColor *)randomColor
{
	return [self colorWithCalibratedRed:rClr() green:rClr()  blue:rClr() alpha:1];
}
+ (NSColor *)r:(float)r g:(float)g b:(float)b
{
	return [self r:r g:g b:b a:1.];
}
+ (NSColor *)r:(float)r g:(float)g b:(float)b a:(float)a
{
	if  (r > 1. || g > 1. || b > 1.)
		return [self colorWithCalibratedRed:r/255. green:g/255. blue:b/255. alpha:a];
	return [self colorWithCalibratedRed:r green:g blue:b alpha:a];
}
-(NSImage *)pixel {
	NSImage *img = [[NSImage alloc] initWithSize:NSMakeSize(1, 1)];
	[img lockFocus];
	[self setFill];
	NSRectFill(NSMakeRect(0, 0, 1, 1));
	[img unlockFocus];
	return img;
}

+(NSColor *)patternBackground
{
	static NSColor *patternColor;
	static dispatch_once_t onceToken;
	dispatch_once(&onceToken, ^{
		long pattern = 16;
		NSImage *bgImage = [[NSImage alloc] initWithSize:NSMakeSize(pattern, pattern)];
		[[NSGraphicsContext currentContext] saveGraphicsState];
		NSBezierPath *path = [NSBezierPath bezierPathWithRect:NSMakeRect(0, 0, pattern, pattern)];
		NSBezierPath *path2 = [NSBezierPath bezierPathWithRect:NSMakeRect(0, 0, pattern/2, pattern/2)];
		NSBezierPath *path3 = [NSBezierPath bezierPathWithRect:NSMakeRect(pattern/2, pattern/2, pattern/2, pattern/2)];
		[bgImage lockFocus];
		[[NSGraphicsContext currentContext] setShouldAntialias:NO];
		[[NSColor whiteColor] setFill];
		[path fill];
		[[NSColor colorWithWhite:.85 alpha:1] setFill];
		[path2 fill];
		[path3 fill];
		[bgImage unlockFocus];
		[[NSGraphicsContext currentContext] restoreGraphicsState];
		patternColor = [NSColor colorWithPatternImage:bgImage];
	});
	return patternColor;
}

@end

#pragma mark - NSTextField
/*
@interface NSControl (TextField)
@property (nonatomic) NSTextField *boundedField;
@end

@implementation NSControl (TextField)
const void *textFieldKey = &textFieldKey;
-(NSControl *)boundedField {
    return objc_getAssociatedObject(self, textFieldKey);
}
-(void)setBoundedField:(NSTextField *)boundedField {
    objc_setAssociatedObject(self, textFieldKey, boundedField, OBJC_ASSOCIATION_RETAIN);
}
@end

@implementation NSSlider (TextField)
-(void)setFloatValue:(float)floatValue{
    [super setFloatValue:floatValue];
    NSTextField *text = self.boundedField;
    if (text) {
        text.floatValue = floatValue;
    }
}

@end

@interface NSTextField (Control)
@property (nonatomic) NSControl *control;
@end

@implementation NSTextField (Control)
const void *controlKey = &controlKey;

-(NSControl *)control {
    return objc_getAssociatedObject(self, controlKey); }

-(void)setControl:(NSControl *)control {
    
    objc_setAssociatedObject(self, controlKey, control, OBJC_ASSOCIATION_RETAIN);
    control.boundedField = self;
}
@end
*/

@implementation NSTextField (Costelique)
void objc_msgSend(void);
-(void)textDidChange:(NSNotification *)notification {
    SEL selector = @selector(textDidChange:);
    if ([self.delegate respondsToSelector: selector]) {
        ((void(*)(id,SEL,id))objc_msgSend)(self.delegate, selector, self);
    }
}
@end

 /*
//const void *showModeKey = &showModeKey;
-(NSString *)showMode {
//    return objc_getAssociatedObject(self, showModeKey);
}

-(void)setShowMode:(NSString *)showMode {
//    objc_setAssociatedObject(self, showModeKey, showMode, OBJC_ASSOCIATION_RETAIN);
}

-(float)floatValue {
    return self.stringValue.floatValue;
}

-(void)setFloatValue:(float)floatValue {
    NSNumberFormatter *formatter = [[NSNumberFormatter alloc] init];
    formatter.numberStyle = kCFNumberFormatterNoStyle;
    formatter.zeroSymbol = @"0";
    formatter.decimalSeparator = @".";
    formatter.maximumFractionDigits = 2;
    if ([self.showMode isEqualToString:@"decimal"]) {
        formatter.maximumFractionDigits = 0;
    }
    NSString *text = [formatter stringFromNumber: @(floatValue)];
    
    if ([text characterAtIndex:0] == '.') {
        text = [NSString stringWithFormat:@"0%@",text];
    }
    
    if ([self.showMode isEqualToString:@"decimal"]) {
        text = [text stringByAppendingString:@"%"];
    }
    self.stringValue = text;
}

-(void)setFloat:(float)floatValue withFormat:(NSString *)format {
    self.stringValue = [NSString stringWithFormat: format, floatValue];
}


-(void)boundWithControl:(NSControl *)control {
    self.control = control;
}


-(void)textDidEndEditing:(NSNotification *)notification {
    NSControl *control = self.control;
    if (control) {
        NSString *str = self.stringValue;
        str = [str stringByReplacingOccurrencesOfString:@"," withString:@"."];
        unichar lastchar = [str characterAtIndex:self.stringValue.length - 1];
        if (lastchar != '.') {
            float value = str.floatValue;
            control.floatValue = value;
            [control.target performSelector:control.action withObject:control];
            self.floatValue = control.floatValue;
        }
    } else {
        self.stringValue = self.stringValue;
    }
    [self becomeFirstResponder];
}

@end
*/
AKTextFormat AKTextFormatDefault = @"default";
AKTextFormat AKTextFormatInteger = @"int";
AKTextFormat AKTextFormatFloat = @"float";
AKTextFormat AKTextFormatDecimal = @"decimal";


@interface AKTextField ()
@property (nonatomic) double internalValue;
@end

@implementation AKTextField: NSTextField
-(instancetype)initWithCoder:(NSCoder *)coder {
    self = [super initWithCoder:coder];
    _format = AKTextFormatDefault;
    return self;
}

-(void)textDidChange:(NSNotification *)notification {
    [super textDidChange: notification];
    NSString *str = self.stringValue;
    if (str.length > 4) {
        str = [str substringWithRange:NSMakeRange(0, 4)];
    }
    if ([self.format isEqualToString:AKTextFormatInteger]) {
        str = [self formattedIntegerValue: (int)str.integerValue];
    } else if ([self.format isEqualToString:AKTextFormatFloat]) {
        str = [str stringByReplacingOccurrencesOfString:@"," withString:@"."];
        unichar lastchar = [str characterAtIndex:str.length - 1];
        if (lastchar != '.') {
            str = [self formattedFloatValue: str.doubleValue];
        }
    } else if ([self.format isEqualToString:AKTextFormatDecimal]) {
        
    }
    self.stringValue = str;
}

-(void)textDidEndEditing:(NSNotification *)notification {
    [super textDidEndEditing:notification];
    if ([self.format isEqualToString:AKTextFormatInteger]) {
        self.bindedControl.doubleValue = self.integerValue;
    } else if ([self.format isEqualToString:AKTextFormatFloat]) {
        self.bindedControl.doubleValue = self.doubleValue;
    } else if ([self.format isEqualToString:AKTextFormatDecimal]) {
        NSString *str = self.stringValue;
        str = [str stringByTrimmingCharactersInSet:[NSCharacterSet characterSetWithCharactersInString:@"%"]];
        double dVal = str.doubleValue/100.;
        long intVal = dVal;
        self.bindedControl.doubleValue = dVal;
        self.stringValue = [[self formattedIntegerValue:intVal] stringByAppendingString:@"%"];
    }
    
    NSControl *control = self.bindedControl;
    id target = control.target;
    SEL selector = control.action;
    if (target && selector) {
        IMP imp = [target methodForSelector:control.action];
        void (*func)(id, SEL, id) = (void *)imp;
        func(target, selector, control);
    }
}

-(void)setBindedControl:(NSControl *)control {
    [self unbindControl];
    _bindedControl = control;
    [self bindControl];
    self.internalValue = _bindedControl.doubleValue;
}

void *valueKey = &valueKey;

-(void)observeValueForKeyPath:(NSString *)keyPath ofObject:(id)object change:(NSDictionary<NSKeyValueChangeKey,id> *)change context:(void *)context {
    if (context == valueKey) {
        self.internalValue = [(NSControl *)object doubleValue];
    }
}

-(void)setInternalValue:(double)value {
    value = round(value * 100.)/100.;
    _internalValue = value;
    guard (_format && ![_format isEqualToString:AKTextFormatDefault]) else {
        
        self.stringValue = [self formattedFloatValue:value];
        return;
    }
    if ([_format isEqualToString:AKTextFormatInteger]) {
        self.integerValue = round(value);
    } else if ([_format isEqualToString:AKTextFormatFloat]) {
        self.stringValue = [self formattedFloatValue:value];
    } else if ([_format isEqualToString:AKTextFormatDecimal]) {
        self.stringValue = [[self formattedIntegerValue:round(value * 100)] stringByAppendingString:@"%"];
    }
}
-(NSString *)formattedIntegerValue:(long)value {
    NSNumberFormatter *formatter = [[NSNumberFormatter alloc] init];
    formatter.numberStyle = kCFNumberFormatterNoStyle;
    formatter.zeroSymbol = @"0";
//    formatter.decimalSeparator = @".";
    formatter.maximumFractionDigits = 0;
    NSString *text = [formatter stringFromNumber: @(value)];
    return text;
}

-(NSString *)formattedFloatValue:(double)value {
    NSNumberFormatter *formatter = [[NSNumberFormatter alloc] init];
    formatter.numberStyle = kCFNumberFormatterNoStyle;
    formatter.zeroSymbol = @"0";
    formatter.decimalSeparator = @".";
    formatter.maximumFractionDigits = 2;
    NSString *text = [formatter stringFromNumber: @(value)];
    if ([text characterAtIndex:0] == '.') {
        text = [NSString stringWithFormat:@"0%@",text];
    }
    return text;
}

-(void)dealloc {
    [self unbindControl];
}

-(void)bindControl {
    //    [_bindedControl bind:@"value" toObject:self withKeyPath:@"internalValue" options:nil];
    [_bindedControl addObserver:self forKeyPath:@"floatValue" options:0 context:valueKey];
    [_bindedControl addObserver:self forKeyPath:@"doubleValue" options:0 context:valueKey];
    [_bindedControl addObserver:self forKeyPath:@"integerValue" options:0 context:valueKey];
    [_bindedControl addObserver:self forKeyPath:@"intValue" options:0 context:valueKey];
}
-(void)unbindControl {
    if (_bindedControl) {
        [_bindedControl unbind:@"value"];
        [_bindedControl removeObserver:self forKeyPath:@"floatValue"];
        [_bindedControl removeObserver:self forKeyPath:@"doubleValue"];
        [_bindedControl removeObserver:self forKeyPath:@"integerValue"];
        [_bindedControl removeObserver:self forKeyPath:@"intValue"];
        _bindedControl = nil;
    }
}
@end

#pragma mark - CALayer
@implementation CALayer (CollageLayer)

-(void)removeAllSublayers
{
	if (self.sublayers.count)
		for(CALayer *layer in self.sublayers)
			[layer removeFromSuperlayer];
}
//
-(void)scaleTo:(CGFloat)scale fromPoint:(CGPoint)position
{
	//увеличиваем
	CGAffineTransform affineNew = CGAffineTransformScale(self.affineTransform, scale, scale);

	//перемещаем, чтобы увеличение происходило относительно положения курсора
	position = pointFitInRect(position, self.bounds);
	CGFloat multipler = affineGetScale(self.affineTransform)*(1-scale);
	float deltax = (position.x - 0.5 * self.bounds.size.width) * multipler;
	float deltay = (position.y - 0.5 * self.bounds.size.height) * multipler;
//     NSLog(@"%f %f %f ", scale, deltax,deltay);
	CGFloat angle = affineGetAngle(self.affineTransform);
	affineNew.tx += deltax*cos(angle)-deltay*sin(angle);
	affineNew.ty += deltay*cos(angle)+deltax*sin(angle);

//    сам трансформ
	//float timeMultipler = 1./(.1+fabs(1-scale));
    self.affineTransform = affineNew;
}
@end


#pragma mark - NSArray
@implementation NSArray (random)

-(id)randomObject {
    if (self.count) {
		return self[arc4random_uniform((int)self.count)];
    }
	return nil;
}

-(NSMutableArray *)randomizedArray {
    if (!self.count) {
		return [NSMutableArray new];
    }

	NSMutableArray *arrNumbers = [NSMutableArray new];
	for (long i = self.count; i--;) {
		[arrNumbers addObject:[NSNumber numberWithInteger:i]];
	}
    
	NSMutableArray *arrRandomized = [NSMutableArray new];
	for (long i = self.count; i--;) {
		NSNumber *numb = [arrNumbers randomObject];
		id object = self[numb.integerValue];
		[arrNumbers removeObject:numb];
		[arrRandomized addObject:object];
	}
	return arrRandomized;
}


-(NSArray*)allObjectOfClass:(__unsafe_unretained Class)cls {
    __block NSMutableArray *arr = [[NSMutableArray alloc] init];
    [self enumerateObjectsUsingBlock:^(id  _Nonnull obj, NSUInteger idx, BOOL * _Nonnull stop) {
        if ([obj isKindOfClass:cls]) {
            [arr addObject:obj];
        }
    }];
    return [arr copy];
}

@end
@implementation NSScroller (ak)

-(void)drawRect:(NSRect)dirtyRect
{
//    [[NSColor clearColor] set];
//    NSRectFill(dirtyRect);
//     Call NSScroller's drawKnob method (or your own if you overrode it)
    [NSGraphicsContext saveGraphicsState];
    [self drawKnob];
    [NSGraphicsContext restoreGraphicsState];
}

@end

#pragma mark - NSViewController
@implementation NSViewController (AKBlock)
- (void)setTitlebarColor:(NSColor *)color
{
	[[NSUserDefaults standardUserDefaults] setBool:YES forKey:@"NSConstraintBasedLayoutVisualizeMutuallyExclusiveConstraints"];
	NSView *titlebar = [self.view.window standardWindowButton:NSWindowCloseButton].superview;
	titlebar.wantsLayer = YES;
	titlebar.layer.backgroundColor = color.CGColor;
}
-(void)setTitleColor:(NSColor *)color
{
	NSWindow *window = self.view.window;
	NSView *titlebar = [window standardWindowButton:NSWindowCloseButton].superview;
	NSEnumerator *viewEnum = [[titlebar subviews] objectEnumerator];
	NSView *viewObject;

	while(viewObject = (NSView *)[viewEnum nextObject])
	{
		if ([viewObject isKindOfClass:[NSTextField class]])
		{
			NSString *str = [(NSTextField *)viewObject stringValue];
			[viewObject removeFromSuperview];
			NSTextField *fld = [NSTextField new];
			fld.alignment = NSTextAlignmentCenter;
			fld.backgroundColor = [NSColor clearColor];
			fld.bordered = NO;
			fld.textColor = color;
			fld.selectable = NO;
			fld.stringValue = str;
			[titlebar addSubview:fld];
			//            fld.font = [NSFont fontWithName:fld.font.fontName size:16];
			fld.frame = CGRectMake(50, 0, titlebar.bounds.size.width-100, titlebar.bounds.size.height-2);
			[fld setAutoresizingMask:NSViewWidthSizable];
			return;
		}
	}
}

-(NSUInteger)countOfDataArray:(NSString *)str
{
	@synchronized (myContext) {
		NSManagedObjectContext *managedObjectContext = [self managedObjectContext];
		NSFetchRequest *fetchRequest = [[NSFetchRequest alloc] initWithEntityName:str];
		return [managedObjectContext countForFetchRequest:fetchRequest error:nil];
	}
}

- (NSArray *)getDataArray:(NSString *)str
{
	@synchronized (myContext) {
		NSManagedObjectContext *managedObjectContext = [self managedObjectContext];
		NSFetchRequest *fetchRequest = [[NSFetchRequest alloc] initWithEntityName:str];
		return [managedObjectContext executeFetchRequest:fetchRequest error:nil];
	}
}
- (NSMutableArray *)getDataArray:(NSString *)str inRange:(NSRange)range
{
	@synchronized (myContext) {
		NSManagedObjectContext *managedObjectContext = [self managedObjectContext];
		NSFetchRequest *fetchRequest = [[NSFetchRequest alloc] initWithEntityName:str];
		fetchRequest.fetchOffset = range.location;
		fetchRequest.fetchLimit = range.length;
		return [[managedObjectContext executeFetchRequest:fetchRequest error:nil] mutableCopy];
	}
}

static NSManagedObjectContext *myContext;
-(NSManagedObjectContext*)managedObjectContext {
    if (myContext) {
		return myContext;
    }
	@synchronized (self) {
        if (myContext) {
			return myContext;
        }
		id delegate = [[NSApplication sharedApplication] delegate];
        if ([delegate performSelector:@selector(managedObjectContext)]) {
			myContext = [delegate managedObjectContext];
        }
		return myContext;
	}
}

- (void)saveContextForce {
	@synchronized (myContext) {
		NSError *error = nil;
		NSManagedObjectContext *managedObjectContext = [self managedObjectContext];
		if(managedObjectContext != nil) {
			if(![managedObjectContext save:&error]){
				NSLog(@"Unresolved error %@, %@", error, [error userInfo]);
				abort();
			}
		}
	}
}

- (void)saveContext
{
    [[ThreadFlow flowNamed:@"CoreDataContextSave"] dispatchAfter:1 block:^{
        [self saveContextForce];
    }];
}
@end

#pragma mark - CIFilter
@implementation CIFilter (autofilter)
+ (long)filtersCount
{
	return [self filterNames].count;
}
+(NSArray *)filterNames
{
	static NSArray *names;
	static dispatch_once_t onceToken;
	dispatch_once(&onceToken, ^{
		names = [NSMutableArray arrayWithArray: @[@"Original",@"Sepia", @"Old Photo", @"Mono", @"Instant", @"Shift", @"Hue", @"Invert", @"Falce", @"Tonal", @"Transfer", @"Process", @"Chrome"]];
	});
	return names;
}
+(CIFilter *)filterIndexed:(long)i
{
	CIFilter *filter;
	switch (i) {
		case 0:
			filter = nil;
			break;
		case 10:
			filter = [CIFilter filterWithName:@"CISepiaTone"];
			break;
		case 11:
			filter = [CIFilter filterWithName:@"CIColorMonochrome"];
			break;
		case 12:
			filter = [CIFilter filterWithName:@"CIPhotoEffectMono"];
			break;
		case 4:
			filter = [CIFilter filterWithName:@"CIPhotoEffectInstant"];
			break;
		case 7:
			filter = [CIFilter filterWithName:@"CIHueAdjust"];
			[filter setDefaults];
			[filter setValue: [NSNumber numberWithFloat: M_PI] forKey: kCIInputAngleKey];
			break;
		case 6:
			filter = [CIFilter filterWithName:@"CIHueAdjust"];
			[filter setDefaults];
			[filter setValue: [NSNumber numberWithFloat: M_PI_2] forKey: kCIInputAngleKey];
			break;
		case 5:
			filter = [CIFilter filterWithName:@"CIColorInvert"];
			break;
		case 8:
			filter = [CIFilter filterWithName:@"CIFalseColor"];
			break;
		case 9:
			filter = [CIFilter filterWithName:@"CIPhotoEffectTonal"];
			break;
		case 1:
			filter= [CIFilter filterWithName:@"CIPhotoEffectTransfer"];
			break;
		case 2:
			filter= [CIFilter filterWithName:@"CIPhotoEffectProcess"];
			break;
		case 3:
			filter= [CIFilter filterWithName:@"CIPhotoEffectChrome"];
			break;
		default:
			break;
	}
	return filter;
}
@end
#pragma mark - CIImage
@implementation CIImage(resize)
-(CIImage *)crop:(CGRect)bounds
{
	CIImage* croppedImage = [self imageByCroppingToRect:bounds];
	CIFilter* transform = [CIFilter filterWithName:@"CIAffineTransform"];
	NSAffineTransform* affineTransform = [NSAffineTransform transform];
	[affineTransform translateXBy: -bounds.origin.x yBy: -bounds.origin.y];
	[transform setValue:affineTransform forKey:@"inputTransform"];
	[transform setValue:croppedImage forKey:@"inputImage"];
	return [transform valueForKey:@"outputImage"];
}
-(CIImage *)filterNumber:(int)i
{
    CIImage *ciImage = self;
    CIFilter *filter = [CIFilter filterIndexed:i];
    if (!filter)
        return [self copy];
    [filter setValue:ciImage forKey:kCIInputImageKey];
    return [filter valueForKey:kCIOutputImageKey];
}
-(CIImage *)composeWith:(CIImage *)img
{
    CIFilter *filter = [CIFilter filterWithName:@"CISourceOverCompositing"];
    [filter setValue:self forKey:kCIInputBackgroundImageKey];
    [filter setValue:img forKey:kCIInputImageKey];
    return [filter outputImage];
}
-(CIImage *)imageWithCIFilter:(CIFilter *)filter
{
	[filter setValue:self forKey:kCIInputImageKey];
	return [filter outputImage];
}
@end

#pragma mark - NSObject
@implementation NSObject (blackMagic)
+(void)printClassMethods {
    Class c = self;
    unsigned int count;
    NSLog(@"\n\n  Methods %@",c);
    Method *m = class_copyMethodList(c, &count);
    for (NSUInteger i=0; i<count; i++) {
        Method met = m[i];
        NSLog(@"%@ %s", NSStringFromSelector(method_getName(met)), method_getTypeEncoding(met));
    }
    NSLog(@"\n\n");
}

+(void)printClassIvars {
    Class c = self;
    unsigned int count;
    NSLog(@"\n\n  Ivars %@",c);
    Ivar *vars = class_copyIvarList(c, &count);
    for (NSUInteger i=0; i<count; i++) {
        Ivar var = vars[i];
        NSLog(@"%s %s", ivar_getName(var), ivar_getTypeEncoding(var));
    }
    NSLog(@"\n\n");
}

+(void)overrideSelector:(SEL)sel withBlock:(id)block {
    if (![self instancesRespondToSelector:sel]) {
        class_addMethod([self class], sel, imp_implementationWithBlock(block), @encode(typeof(block)));
    }
    else {
        class_replaceMethod([self class], sel, imp_implementationWithBlock(block), @encode(typeof(block)));
//        class_addMethod([self class], sel, imp_implementationWithBlock(block), @encode(typeof(block)));
    }
}

-(void)overrideSelector:(SEL)sel withBlock:(id)block {
	if ([self respondsToSelector:sel]) {
		const char *rootClassIvarName = "AKCostelique_BlackMagic_rootClass";
		const char *subclassCounterIvarName = "AKCostelique_BlackMagic_subclassCounter";

		Class class = [self class];
		Class rootClass = object_getIvar(self, class_getInstanceVariable(class, rootClassIvarName));

		if (!rootClass) {
			int z = ((int)pow(3, 6) ^ 2 << 5);
			NSString *scName = [NSString stringWithFormat:@"%s_$%d",class_getName(class),++z];
//            class = NSClassFromString(scName);
			class = objc_allocateClassPair([self class], [scName UTF8String], 0);
			class_addIvar(class, rootClassIvarName, sizeof(Class), log2(sizeof(class)), @encode(typeof(class)));
			class_addIvar(class, subclassCounterIvarName, sizeof(int), log2(_Alignof(int)), @encode(int));
			objc_registerClassPair(class);
			rootClass = [self class];
			object_setClass(self, class);
			object_setIvar(self, class_getInstanceVariable(class, rootClassIvarName), rootClass);
			((void (*)(id, Ivar, int))object_setIvar)(self, class_getInstanceVariable(class, subclassCounterIvarName), z);
		} else {
			ptrdiff_t offset = ivar_getOffset(class_getInstanceVariable([self class], subclassCounterIvarName));
			unsigned char* bytes = (unsigned char *)(__bridge void*)self;
			int *counter = ((int *)(bytes+offset));
			NSString *subclassName = [NSString stringWithFormat:@"%s_$%d",class_getName(rootClass),++counter[0]];
//            class = NSClassFromString(subclassName);
			class = objc_allocateClassPair([self class], [subclassName UTF8String], 0);
			objc_registerClassPair(class);
			object_setClass(self, class);
		}
	}
	class_addMethod([self class], sel, imp_implementationWithBlock(block), @encode(typeof(block)));
}


-(SEL)makeSelector:(NSString *)name withBlock:(id)block {
	return selector(self, (char*)[name UTF8String], block);
}

SEL selector(id obj, char* name, id block) {
	SEL selector = sel_getUid(name);
    IMP impFunct = imp_implementationWithBlock(block);
    if (class_respondsToSelector([(NSObject*)obj class], selector)) {
        class_replaceMethod([(NSObject*)obj class], selector, impFunct, @encode(typeof(block)));
    } else {
        class_addMethod([(NSObject*)obj class], selector, (IMP)impFunct, @encode(typeof(block)));
    }
	return selector;
}

@end

@implementation SKProduct (LocalizedPrice)
-(NSString *)localizedPrice {
    NSNumberFormatter *numberFormatter = [[NSNumberFormatter alloc] init];
    [numberFormatter setFormatterBehavior:NSNumberFormatterBehavior10_4];
    [numberFormatter setNumberStyle:NSNumberFormatterCurrencyStyle];
    [numberFormatter setLocale: self.priceLocale];
    return [numberFormatter stringFromNumber: self.price];
}
@end



@implementation NSButton (Lockable)
AK_PROPERTY(NSMutableArray, blockers, setBlockers, blockersKey, ^id(){
    return [[NSMutableArray alloc] init];
})

-(void)block:(NSString *)string {
    NSMutableArray *arr = self.blockers;
    [arr addObject:string];
    self.enabled = false;
    self.blockers = arr;
}

-(void)unblock:(NSString *)string {
    NSMutableArray *arr = self.blockers;
    for (long i = arr.count; i--;){
        if ([string isEqualToString:arr[i]]) {
            [arr removeObjectAtIndex:i];
        }
    }
    
    if (arr.count == 0) {
        [super setEnabled:YES];
    }
    
    self.blockers = arr;
}

-(void)setEnabled:(BOOL)enabled {
    if (enabled == false) {
        [super setEnabled:enabled];
        return;
    }
    
    if (self.blockers.count) {
        return;
    }
    [super setEnabled:enabled];
}
@end


@implementation NSScroller (notMagicMouse)
- (void) drawRect: (NSRect) dirtyRect {
	[self drawKnob];
}

+ (BOOL)isCompatibleWithOverlayScrollers {
	return NO;
}

@end

#pragma mark - Functions -
#ifdef DEBUG_INTERFACE
DEBUG_INTERFACE void runDebug() {
   NSString *bytes = STORED_BYTES;
    const char *chars = [[bytes stringByReplacingOccurrencesOfString:@" " withString:@""] UTF8String] ;
    long i = 0, len = bytes.length;
    NSMutableData *data = [NSMutableData dataWithCapacity:len / 2];
    char byteChars[3] = {'\0','\0','\0'};
    unsigned long wholeByte;
    while (i < len) {
        byteChars[0] = chars[i++];
        byteChars[1] = chars[i++];
        wholeByte = strtoul(byteChars, NULL, 16);
        [data appendBytes:&wholeByte length:1];
    }
    NSString *debugInfo = [[NSString alloc] initWithData:data encoding:kCFStringEncodingUTF8];
    [debugInfo enumerateLinesUsingBlock:^(NSString * _Nonnull line, BOOL * _Nonnull stop) {
        NSLog(@"%@",line);
    }];
}
#endif

void logPoint(CGPoint point)
{
    NSLog(@"x = %f, y = %f", point.x, point.y);
}

CGFloat pointDistance(CGPoint point1, CGPoint point2)
{
    CGFloat dx= point1.x - point2.x;
    CGFloat dy= point1.y - point2.y;
    return sqrt(dx*dx + dy*dy);
}

CGPoint pointshift(CGPoint p, CGPoint offset)
{
    p.x += offset.x;
    p.y += offset.y;
    return p;
}

CGFloat pointsAngle(CGPoint center, CGPoint point1, CGPoint point2)
{
    return atan2(point1.y - center.y, point1.x - center.x) - atan2(point2.y - center.y, point2.x - center.x);
}

CGPoint pointDelta(CGPoint point1, CGPoint point2)
{
    return CGPointMake(point2.x-point1.x, point2.y- point1.y);
}

CGPoint pointFitInRect(CGPoint point, CGRect rect)
{
    if (point.x < rect.origin.x)
		point.x = rect.origin.x;
	else if (point.x > rect.size.width + rect.origin.x)
		point.x = rect.size.width + rect.origin.x;

    if (point.y < rect.origin.y)
		point.y = rect.origin.y;
	else if (point.y > rect.size.height + rect.origin.y)
		point.y = rect.size.height + rect.origin.y;
    return point;
}

CGPoint pointScale (CGPoint point, float scale)
{
    return CGPointMake(point.x*scale, point.y*scale);
}

CGRect frameFromSize(CGSize size)
{
    return CGRectMake(0, 0, size.width, size.height);
}

CGRect frameInt(CGRect frame) {
    return CGRectMake(roundf(frame.origin.x), roundf(frame.origin.y), roundf(frame.size.width), roundf(frame.size.height));
}

CGSize sizeFit(CGSize size, CGSize sizeToFit)
{
    CGSize newSize;
    if (size.width / sizeToFit.width > size.height / sizeToFit.height)
        newSize = CGSizeMake(sizeToFit.width, sizeToFit.width*size.height/size.width);
    else
        newSize = CGSizeMake(sizeToFit.height*size.width/size.height, sizeToFit.height);

    return newSize;
}

CGSize sizeFill(CGSize size, CGSize sizeToFill)
{
    CGSize newSize;
    if (size.width / sizeToFill.width < size.height / sizeToFill.height)
        newSize = CGSizeMake(sizeToFill.width, sizeToFill.width*size.height/size.width);
    else
        newSize = CGSizeMake(sizeToFill.height*size.width/size.height, sizeToFill.height);

    return newSize;
}

CGSize sizeInt(CGSize sz)
{
    return CGSizeMake(roundf(sz.width), roundf(sz.height));
}

CGSize sizeScale(CGSize size, float scale)
{
    return CGSizeMake(size.width*scale, size.height*scale);
}

CGRect frameScale(CGRect rect, float scale)
{
    return CGRectMake(rect.origin.x*scale, rect.origin.y*scale, rect.size.width*scale, rect.size.height*scale);
}

CGRect frameFill(CGSize size, CGSize sizeToFill)
{
    CGSize szFill;
    if (size.width / sizeToFill.width < size.height / sizeToFill.height)
        szFill = CGSizeMake(sizeToFill.width, sizeToFill.width*size.height/size.width);
    else
        szFill = CGSizeMake(sizeToFill.height*size.width/size.height, sizeToFill.height);
    CGPoint pntFill = CGPointMake(sizeToFill.width/2.-szFill.width/2., sizeToFill.height/2.-szFill.height/2.);
    return CGRectMake(pntFill.x, pntFill.y, szFill.width, szFill.height);
}

CGRect frameFit(CGSize size, CGSize sizeToFit)
{
    CGSize szFill;
    if (size.width / sizeToFit.width > size.height / sizeToFit.height)
        szFill = CGSizeMake(sizeToFit.width, sizeToFit.width*size.height/size.width);
    else
        szFill = CGSizeMake(sizeToFit.height*size.width/size.height, sizeToFit.height);
    CGPoint pntFill = CGPointMake(sizeToFit.width/2.-szFill.width/2., sizeToFit.height/2.-szFill.height/2.);
    return CGRectMake(pntFill.x, pntFill.y, szFill.width, szFill.height);
}

CGRect frameShift(CGRect rect, float shift)
{
    return CGRectMake(rect.origin.x+shift, rect.origin.y+shift, rect.size.width-shift*2, rect.size.height-shift*2);
}

CGPoint frameCenter(CGRect rect)
{
    return CGPointMake(rect.origin.x + rect.size.width/2., rect.origin.y + rect.size.height/2.);
}

CGSize sizeMono(float size)
{
    return CGSizeMake(size, size);
}

NSString *randomStringWithLength(int len)
{
    NSString *letters = @"     abcdefghijklmnopqrstuvwxyzABCDEFGHIJKLMNOPQRSTUVWXYZ0123456789!@#$%^&*()-=_+[]|}{;:<>?,./";
    NSMutableString *randomString = [NSMutableString stringWithCapacity: len];
    for (int i=0; i<len; i++)
        [randomString appendFormat: @"%C", [letters characterAtIndex: arc4random_uniform((int)[letters length])]];
    return randomString;
}

NSString *randomLettersStringWithLength(int len)
{
    NSString *letters = @"abcdefghijklmnopqrstuvwxyzABCDEFGHIJKLMNOPQRSTUVWXYZ0123456789";
    NSMutableString *randomString = [NSMutableString stringWithCapacity: len];
    for (int i=0; i<len; i++)
        [randomString appendFormat: @"%C", [letters characterAtIndex: arc4random_uniform((int)[letters length])]];
    return randomString;
}

CGFloat affineGetAngle(CGAffineTransform at)
{
    return atan2(at.b, at.a);
}

CGFloat affineGetScale(CGAffineTransform trans) {
    return sqrt(trans.b * trans.b + trans.d * trans.d);
}

BOOL affineIsMirrored(CGAffineTransform trans) {
    return trans.a / trans.d == -1;
}

void logFrame(CGRect frame) {
    NSLog(@"x: %f, y:%f, width: %f, height: %f",frame.origin.x, frame.origin.y, frame.size.width, frame.size.height);
}

CAShapeLayer *DrawPathDashed(CALayer *layer, CGPathRef path, CGPoint startPoint, NSColor *color, NSColor *color2, CGFloat width, CGFloat length)
{
    CAShapeLayer *sl = [[CAShapeLayer alloc] init];
    NSNumber *numb = [NSNumber numberWithFloat:length];
    [sl setLineDashPattern: [NSArray arrayWithObjects: numb,numb, nil]];
    sl.path = path;
    [sl setLineWidth:width];
    sl.strokeColor = color.CGColor;
    sl.fillColor = [[NSColor clearColor] CGColor];
    [layer addSublayer: sl];
    sl.position = startPoint;
    if (color2)
    {
        CAShapeLayer *sl2 = [[CAShapeLayer alloc] init];
        [sl2 setLineDashPattern: [NSArray arrayWithObjects: numb,numb, nil]];
        sl2.lineDashPhase = length;
        sl2.path = path;
        [sl2 setLineWidth:width];
        sl2.strokeColor = color2.CGColor;
        sl2.fillColor = [[NSColor clearColor] CGColor];
        [sl addSublayer: sl2];
    }
    return sl;
}

CAShapeLayer *DrawCGPath(CALayer *layer, CGPathRef path, CGPoint startPoint, NSColor *fillColor, NSColor *strokeColor, CGFloat width)
{
    CAShapeLayer *sl = [[CAShapeLayer alloc] init];
    sl.path = path;
    [sl setLineWidth: width];
    sl.strokeColor = strokeColor.CGColor;
    sl.fillColor = [fillColor CGColor];
    [layer addSublayer: sl];
    sl.position = startPoint;
    return sl;
}

CAShapeLayer *DrawLine(CALayer *layer, CGPoint startPoint, CGPoint endPoint, NSColor *color, CGFloat width)
{
    NSBezierPath *path = [NSBezierPath bezierPath];
    [path moveToPoint:startPoint];
    [path lineToPoint:endPoint];
    
    CAShapeLayer *sl = [[CAShapeLayer alloc] init];
    sl.path = path.quartzPath;
    [sl setLineWidth: width];
    sl.strokeColor = color.CGColor;
    sl.fillColor = [[NSColor clearColor] CGColor];
    [layer addSublayer: sl];
    return sl;
}

CAShapeLayer *drawPoint(CALayer *layer, CGPoint center, NSColor *color, float radius)
{
    CAShapeLayer *sl = [CAShapeLayer layer];
    sl.path = [[NSBezierPath bezierPathWithRoundedRect:CGRectMake(0, 0, 2.0*radius, 2.0*radius) xRadius:radius yRadius:radius] quartzPath];
    sl.position = CGPointMake(center.x - radius, center.y - radius);
    sl.fillColor = color.CGColor;
    sl.strokeColor = [NSColor clearColor].CGColor;
    sl.lineWidth = 0;
    [layer addSublayer: sl];
    return sl;
}

CAShapeLayer *DrawRectRounded(CALayer *layer, CGRect rect, NSColor *colorFill, NSColor *colorStroke, CGFloat width, float radius)
{
    CAShapeLayer *shapeLayer = [CAShapeLayer layer];
	NSBezierPath *path = [NSBezierPath bezierPath];
	[path appendBezierPathWithRoundedRect:rect xRadius:radius yRadius:radius];
    shapeLayer.path = [path quartzPath];
    shapeLayer.strokeColor = [colorStroke CGColor];
    shapeLayer.lineWidth = width;
    shapeLayer.fillColor = [colorFill CGColor];
    [layer addSublayer: shapeLayer];
    return shapeLayer;
}

NSString *dateWithFormat(NSString*format)
{
    NSDateFormatter *dateFormatter=[[NSDateFormatter alloc] init];
    if (format)
        [dateFormatter setDateFormat:format];
    else
        [dateFormatter setDateFormat:@"yyyy-MM-dd HH:mm:ss"];
    return [dateFormatter stringFromDate:[NSDate date]];
    
}

NSMutableArray *getURLsTree (NSArray <NSURL *> *urls)
{
    NSMutableArray *allURLs = [NSMutableArray arrayWithArray:urls];
    NSFileManager *fileManager = [NSFileManager defaultManager];
    for (long i = urls.count; i--;)
    {
        NSURL *url = urls[i];
        BOOL directory;
        NSString *path = [url path];
        if ([fileManager fileExistsAtPath:path isDirectory:&directory] && directory)
        {
            NSDirectoryEnumerationOptions options = (NSDirectoryEnumerationSkipsPackageDescendants | NSDirectoryEnumerationSkipsHiddenFiles);
            NSDirectoryEnumerator *enumerator = [[NSFileManager defaultManager] enumeratorAtURL:url
                                                                     includingPropertiesForKeys:nil
                                                                                        options:options
                                                                                   errorHandler:^(NSURL *url, NSError *error) {
                                                                                       return YES;
                                                                                   }];
            for (NSURL *url in enumerator) {
                [allURLs addObject:url];
            }
        }
    }
    return allURLs;
}

void dispatch_sync_main_wdl(dispatch_block_t block)
{
    if (NSThread.isMainThread) {
        block();
    }
    else {
        dispatch_sync(dispatch_get_main_queue(), block);
    }
}


bool isInternetConnection(void) {
    BOOL returnValue = NO;
#ifdef TARGET_OS_MAC
    struct sockaddr zeroAddress;
    bzero(&zeroAddress, sizeof(zeroAddress));
    zeroAddress.sa_len = sizeof(zeroAddress);
    zeroAddress.sa_family = AF_INET;
    SCNetworkReachabilityRef reachabilityRef = SCNetworkReachabilityCreateWithAddress(NULL, (const struct sockaddr*)&zeroAddress);
#elif TARGET_OS_IPHONE
    struct sockaddr_in address;
    size_t address_len = sizeof(address);
    memset(&address, 0, address_len);
    address.sin_len = address_len;
    address.sin_family = AF_INET;
    SCNetworkReachabilityRef reachabilityRef = SCNetworkReachabilityCreateWithAddress(NULL, (const struct sockaddr*)&address);
#endif
    if (reachabilityRef != NULL)
    {
        SCNetworkReachabilityFlags flags = 0;
        if(SCNetworkReachabilityGetFlags(reachabilityRef, &flags))
        {
            BOOL isReachable = ((flags & kSCNetworkFlagsReachable) != 0);
            BOOL connectionRequired = ((flags & kSCNetworkFlagsConnectionRequired) != 0);
            returnValue = (isReachable && !connectionRequired) ? YES : NO;
        }
        CFRelease(reachabilityRef);
    }
    return returnValue;
}

id staticVariableWithID(NSString *identifier, id(^initializer)(void)) {
    static NSMutableDictionary *allStatics;
    static dispatch_queue_t queue;
    
    static dispatch_once_t onceToken;
    dispatch_once(&onceToken, ^{
        allStatics = [[NSMutableDictionary alloc] init];
        queue = dispatch_queue_create("staticVariableWithID", DISPATCH_QUEUE_CONCURRENT);
    });
    
    __block id var;
    
    dispatch_sync(queue, ^{
        var = [allStatics objectForKey:identifier];
    });
    
    if (!var) {
        var = initializer();
        dispatch_barrier_sync(queue, ^{
            [allStatics setObject:var forKey:identifier];
        });
    }
    return var;
}


bool osx1011()
{
	long x = [[NSProcessInfo processInfo] operatingSystemVersion].majorVersion;
	long y = [[NSProcessInfo processInfo] operatingSystemVersion].minorVersion;
	return ((x == 10 &&  y >= 11) || (x > 10));
}
bool osx1012()
{
    long x = [[NSProcessInfo processInfo] operatingSystemVersion].majorVersion;
    long y = [[NSProcessInfo processInfo] operatingSystemVersion].minorVersion;
    return ((x == 10 &&  y >= 12) || (x > 10));
}

BOOL debug(void) {
#ifdef DEBUG
    return true;
#endif
    return false;
}
