//
//  AKFunctions.h
//  testestest
//
//  Created by Олег on 29.02.16.
//  Copyright © 2016 Admin. All rights reserved.
//

#import <Cocoa/Cocoa.h>
#import <QuartzCore/QuartzCore.h>
#import <StoreKit/SKProduct.h>

//#pragma clang diagnostic ignored "-Wnullability-completeness"

#define UserDefs [NSUserDefaults standardUserDefaults]
#define CORES_COUNT [[NSProcessInfo processInfo] activeProcessorCount]
#define MACOS10_11 osx1011()
#define MACOS10_12 osx1012()

#define guard(x) if (x) {}
NS_ASSUME_NONNULL_BEGIN

#pragma mark -  Custom classes -
@interface AKTimer : NSObject
@property BOOL clearOnPrint;

+(void)start;
+(void)log;
+(void)logWithString:(NSString *)string;

+(instancetype)timerNamed:(NSString *)str;
+(instancetype)timerStarted;

-(void)reset;
-(void)log:(NSString *)str;
-(void)print;
-(void)printAfterIterations:(NSInteger)iterations;
@end

@interface Geometry : NSObject
@property (readonly, class) Geometry *(^size)(CGSize sz);
@property (readonly, class) Geometry *(^frame)(CGRect rct);
@property (readonly, class) Geometry *(^point)(CGPoint pnt);

@property (readonly) Geometry *(^fill)(CGSize sizeToFill);
@property (readonly) Geometry *(^fit)(CGSize sizeToFit);
@property (readonly) Geometry *(^scale)(CGFloat scale);
@property (readonly) Geometry *(^shift)(CGFloat shift);
@property (readonly) Geometry *(^move)(CGPoint move);
@property (readonly) Geometry *(^centerIn)(CGRect rect);
@property (readonly) Geometry *(^boundIn)(CGRect rect);
@property (readonly) Geometry *(^round)(void);

@property (readonly) CGRect rect;
@property (readonly) CGRect frame;
@property (readonly) CGPoint point;
@property (readonly) CGSize size;
@property (readonly) CGPoint center;

@property (readonly) CGFloat x;
@property (readonly) CGFloat y;
@property (readonly) CGFloat width;
@property (readonly) CGFloat height;
@end

@interface G: Geometry
@end

@class DragView;

@protocol DragViewDelegate <NSObject>
@required
-(void)dragView:(DragView *)vi filesComplete:(NSArray <NSURL *> *)urls needsWait:(bool)wait;
@optional
-(void)dragView:(DragView *)vi filesPerform:(NSArray <NSURL *> *)urls newSession:(bool)newSession;
-(void)dragViewExited:(DragView *)vi;
-(void)dragViewCancelled:(DragView *)vi;
@end

@interface DragView: NSView <NSDraggingDestination>
@property (nonatomic) IBInspectable NSInteger showImage;
@property IBOutlet id <DragViewDelegate> delegate;
@property (nonatomic) IBInspectable NSImage * image;
@property (nonatomic) IBInspectable NSColor * lineColor;
@property (nonatomic) IBInspectable NSColor * highlightedColor;
@property (nonatomic) IBInspectable bool clickLock;
@property (nonatomic) IBInspectable NSString *strTitle;
@property (nonatomic) IBInspectable NSString *strDescription;
@property (nonatomic) NSString *strInfoText;
@property (nonatomic) bool progressMode;
@property (nonatomic) float progress;
//@property (nonatomic) IBInspectable float lineLength;
@end

@interface  ViewFromXib : NSView
@property (nonatomic, strong) ViewFromXib *customView;
@end

IB_DESIGNABLE
@interface ColorableView : NSView
@property (nonatomic) IBInspectable NSColor * backgroundColor;
@end

IB_DESIGNABLE
@interface GradientView : NSView
@property (nonatomic) IBInspectable NSColor * topColor;
@property (nonatomic) IBInspectable NSColor * bottomColor;
@end

IB_DESIGNABLE
@interface GradientButton : NSButton
@property IBInspectable NSColor *textColor;
@property IBInspectable NSColor *borderColor;
@property IBInspectable NSColor *activeColor;
@property IBInspectable NSColor *activeGradient;
@property IBInspectable NSColor *pressedColor;
@property IBInspectable NSColor *pressedGradient;
@end

@interface ThreadFlow : NSObject
@property (readonly) NSString *name;
+(ThreadFlow *)flowNamed:(NSString *)str;
-(void)dispatchAfter:(float)sec block:(dispatch_block_t)block;
-(void)dispatchPeriodicallyAfter:(float)sec block:(dispatch_block_t)block;
@end

@interface AKMonitor : NSProxy
+(BOOL)altPressed;
+(BOOL)cmndPressed;
+(BOOL)ctrlPressed;
+(BOOL)shiftPressed;
@end

@interface ClickableTextFied: NSTextField
@end

#pragma mark -  Native classes -


@interface NSView (ActionBlock)
-(void)lockMouse;
-(NSArray *)allSubviews;
-(NSImage *)imageRepresentation;
-(NSImage *)imageRepresentation:(CGInterpolationQuality)qual;
-(NSImage *)imageRepresentationOld;
-(void)layerBackground:(NSColor *)color;
-(void)removeAllSubviews;
//-(BOOL)clickInFrame:(CGPoint)abscoord;
-(CALayer *)setImageLayer:(NSImage*)img;
-(void)setMaskWithCornerRadius:(int)rad;
-(void)blockWithoutProgress:(NSString *)blocker;
-(void)blockWithCircular:(NSString *)string;
-(void)unblock:(NSString *)blocker;
-(void)removeADsScaleAnimation;
@end

/*
@interface NSTextField (Costelique)

@end
*/

//TODO: <BoundedField>
typedef NSString *AKTextFormat;

extern AKTextFormat AKTextFormatDefault;
extern AKTextFormat AKTextFormatInteger;
extern AKTextFormat AKTextFormatFloat;
extern AKTextFormat AKTextFormatDecimal;

@interface AKTextField : NSTextField
#if TARGET_INTERFACE_BUILDER
@property (nonatomic) IBInspectable NSString *format;
#else
@property (nonatomic) AKTextFormat format;
#endif
@property (nonatomic) IBOutlet NSControl *_Nullable bindedControl;
@end
//TODO: </BoundedField>

@interface NSEvent (event)
-(CGPoint)locationInView:(NSView *)vi;
@end

@interface NSBezierPath (BezierPathUtilities)
+(NSBezierPath *)bezierPathWithArcInCenter:(NSPoint)centerPoint radius:(float)radius fromAngle:(float)angle1 to:(float)angle2;
-(void)strokeInside;
-(void)strokeInsideWithinRect:(NSRect)clipRect;
-(CGPathRef)quartzPath;
-(CGPathRef)quartzPathWithSize:(CGSize)sz;
@end


@interface NSImage (actions)
+(NSImage*)imageFromCGImageRef:(CGImageRef)image;
+(NSImage *)imageWithCIImage:(CIImage *)img;
+(NSImage *)imageFromURL:(NSURL *)url;
+(NSImage *)imageFromURL:(NSURL *)url async:(bool)async;
-(NSImage *)resize:(NSSize)newSize;
-(NSImage *)crop:(CGRect)newRect;
-(NSImage *)cropToFill:(CGSize)newSize cornerRadius:(float)radius;
-(NSImage *)flipHorisontal:(bool)horiz;
-(NSData *)compressedJPEGData:(float)factor;
-(NSData *)PNGRepresentation;
-(CIImage *)CIImage;
-(CGImageRef)CGImage;
-(NSImage *)filterNumber:(long)index;
-(NSImage *)imageWithCIFilter:(CIFilter *)filter;
-(void)redraw;
@end


@interface NSColor(costelique)
+(NSColor *)randomColor;
+(NSColor *)r:(float)r g:(float)g b:(float)b a:(float)a;
+(NSColor *)r:(float)r g:(float)g b:(float)b;
+(NSColor *)patternBackground;
-(NSImage *)pixel;
@end

@interface NSViewController (AKBlock)
- (void)setTitlebarColor:(NSColor *)color;
-(void)setTitleColor:(NSColor *)color;
-(NSUInteger)countOfDataArray:(NSString *)str;
-(NSMutableArray *)getDataArray:(NSString *)str;
-(NSMutableArray *)getDataArray:(NSString *)str inRange:(NSRange)range;
-(void)saveContext;
- (void)saveContextForce;
-(NSManagedObjectContext*)managedObjectContext;
@end

@interface CALayer (CollageLayer)
-(void) scaleTo:(CGFloat)scale fromPoint:(CGPoint)position;
-(void) removeAllSublayers;
@end

@interface NSArray<__covariant ObjectType> (random)
-(ObjectType) randomObject;
-(NSMutableArray <ObjectType>*)randomizedArray;
-(NSArray <ObjectType>*)allObjectOfClass:(__unsafe_unretained Class)cls;
@end

@interface CIImage(resize)
-(CIImage *)imageWithCIFilter:(CIFilter *)filter;
-(CIImage *)crop:(CGRect)bounds;
-(CIImage *)filterNumber:(int)i;
-(CIImage *)composeWith:(CIImage *)img;
@end

@interface CIFilter (autofilter)
+ (long)filtersCount;
+ (NSArray *)filterNames;
+ (CIFilter *)filterIndexed:(long)i;
@end

@interface NSObject (blackMagic)
+(void)printClassMethods;
+(void)printClassIvars;
+(void)overrideSelector:(SEL)sel withBlock:(id)block;
-(void)overrideSelector:(SEL)sel withBlock:(id)block;
-(SEL)makeSelector:(NSString *)name withBlock:(id)block;
@end

@interface SKProduct (LocalizedPrice)
-(NSString *)localizedPrice;
@end

@interface NSButton (Lockable)
-(void)block:(NSString *)string;
-(void)unblock:(NSString *)string;
@end

#pragma mark -  Functions -

void logPoint(CGPoint point);
void logFrame(CGRect frame);

CGFloat pointDistance(CGPoint point1, CGPoint point2);
CGFloat pointsAngle(CGPoint center, CGPoint point1, CGPoint point2);
CGPoint pointshift (CGPoint p, CGPoint offset);
CGPoint pointDelta (CGPoint point1, CGPoint point2);
CGPoint pointFitInRect (CGPoint point, CGRect rect);
CGPoint pointScale (CGPoint point, float scale);

/*
CGSize sizeScale(CGSize size, float scale);
CGSize sizeFill(CGSize size, CGSize sizeToFill);
CGSize sizeFit(CGSize size, CGSize sizeToFit);
CGSize sizeMono(float size);
CGSize sizeInt(CGSize sz);

CGRect frameInt(CGRect frame);
CGRect frameFit(CGSize size, CGSize sizeToFit);
CGRect frameFill(CGSize size, CGSize sizeToFill);
CGRect frameScale(CGRect rect, float scale);
CGRect frameShift(CGRect rect, float shift);
CGPoint frameCenter(CGRect rect);
*/

//affines
CGFloat affineGetScale(CGAffineTransform trans);
CGFloat affineGetAngle(CGAffineTransform at);
BOOL affineIsMirrored(CGAffineTransform trans);
//draw
CAShapeLayer *DrawLine(CALayer *layer, CGPoint startPoint, CGPoint endPoint, NSColor *color, CGFloat width);
CAShapeLayer *drawPoint(CALayer *layer, CGPoint center, NSColor *color, float radius);
CAShapeLayer *DrawRectRounded(CALayer *layer, CGRect rect, NSColor *colorFill, NSColor *colorStroke, CGFloat width, float radius);

//other
NSString *randomStringWithLength(int len);
NSString *randomLettersStringWithLength(int len);
NSString * _Nullable dateWithFormat(NSString* _Nullable  format);

NSMutableArray *getURLsTree (NSArray <NSURL *> *urls);

void dispatch_sync_main_wdl(dispatch_block_t block);

id staticVariableWithID(NSString *identifier, id(^initializer)(void));

bool isInternetConnection(void);
bool osx1011(void);
bool osx1012(void);

BOOL debug(void);

NS_ASSUME_NONNULL_END
