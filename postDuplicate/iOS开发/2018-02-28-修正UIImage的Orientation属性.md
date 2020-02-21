在 iOS 中展示图片时有时会遇到图片颠倒或者旋转展示的情况，通常来说这与图片的 orientation 值有关系。

## 照片的“方向”

相机拍摄照片时是没有方向概念的，只有使用者明确照片按照什么方向放置最合适，因此对于同一个方向的物体，例如 ^ 上箭头，相机可能的拍摄角度就有上下左右四种，能拍出 ^（上）、V（下）、<（左）、>（右） 这四种情况，而相机并不知道如何放置能正确表现其拍摄内容的方向性。所以现代相机中加入了方向传感器，能将拍摄时的相机方向记录下来，需要显示图片的数字设备就可以根据相机的方向信息来正确摆放目标图片达到合理展示效果。

而这一方向信息就存放于图像的 Exif 中。EXIF 是一种可交换图像文件格式，可以附加于 JPEG、TIFF、RIFF 格式的图像文件中，包含拍摄信息的内容和索引图或图像处理软件的版本等信息，也包括这里的方向信息 orientation。

orientation 定义了八个值

|Value|0th Row|0th Column|
|---|---|---|
|1|top|left side|
|2|top|right side|
|3|bottom|right side|
|4|bottom|left side|
|5|left side|top|
|6|right side|top|
|7|right side|bottom|
|8|left side|bottom|

它们具体的区分如下图所示

<img src="https://github.com/Yasic/FixImageOrientation/blob/master/SampleImage/EXIFOrientation.png?raw=true" width=500>

从图中可以看到，表格将图片的 0th Row 定义为顶边线，0th Column 定义为左边线。例如，对于 orientation 为 1，顶边线就在顶部，左边线就在左边，所以这张照片就是以正常视角拍出来的。

## 正确展示照片

当我们需要在 iOS 中展示一个图片对象 UIImage 时，我们可以通过 UIImage 的 imageOrientation 属性获取到它的 orientation 信息，这是一个枚举值，它的定义如下

```objectivec
typedef NS_ENUM(NSInteger, UIImageOrientation) {
    UIImageOrientationUp,            // default orientation
    UIImageOrientationDown,          // 180 deg rotation
    UIImageOrientationLeft,          // 90 deg CCW
    UIImageOrientationRight,         // 90 deg CW
    UIImageOrientationUpMirrored,    // as above but image mirrored along other axis. horizontal flip
    UIImageOrientationDownMirrored,  // horizontal flip
    UIImageOrientationLeftMirrored,  // vertical flip
    UIImageOrientationRightMirrored, // vertical flip
};
```

对应到图片如下

<img src="https://github.com/Yasic/FixImageOrientation/blob/master/SampleImage/UIImageOrientation.png?raw=true" width=500>

所以可以根据 UIImage 的 orientation 属性对 UIImage 做矩阵变换，获得正确方向下的图片再展示，就不会出现展示的图片旋转颠倒的情况了。

Github 有一个 UIImage 的 [category](https://gist.github.com/alex-cellcity/1531596) 流传很广，就是解决这一问题的，恰好在项目的历史代码中看到了，下面是源码

```objectivec
- (UIImage *)fixOrientation {

    // No-op if the orientation is already correct
    if (self.imageOrientation == UIImageOrientationUp) return self;

    // We need to calculate the proper transformation to make the image upright.
    // We do it in 2 steps: Rotate if Left/Right/Down, and then flip if Mirrored.
    CGAffineTransform transform = CGAffineTransformIdentity;

    switch (self.imageOrientation) {
        case UIImageOrientationDown:
        case UIImageOrientationDownMirrored:
            transform = CGAffineTransformTranslate(transform, self.size.width, self.size.height);
            transform = CGAffineTransformRotate(transform, M_PI);
            break;

        case UIImageOrientationLeft:
        case UIImageOrientationLeftMirrored:
            transform = CGAffineTransformTranslate(transform, self.size.width, 0);
            transform = CGAffineTransformRotate(transform, M_PI_2);
            break;

        case UIImageOrientationRight:
        case UIImageOrientationRightMirrored:
            transform = CGAffineTransformTranslate(transform, 0, self.size.height);
            transform = CGAffineTransformRotate(transform, -M_PI_2);
            break;
    }

    switch (self.imageOrientation) {
        case UIImageOrientationUpMirrored:
        case UIImageOrientationDownMirrored:
            transform = CGAffineTransformTranslate(transform, self.size.width, 0);
            transform = CGAffineTransformScale(transform, -1, 1);
            break;

        case UIImageOrientationLeftMirrored:
        case UIImageOrientationRightMirrored:
            transform = CGAffineTransformTranslate(transform, self.size.height, 0);
            transform = CGAffineTransformScale(transform, -1, 1);
            break;
    }

    // Now we draw the underlying CGImage into a new context, applying the transform
    // calculated above.
    CGContextRef ctx = CGBitmapContextCreate(NULL, self.size.width, self.size.height,
                                             CGImageGetBitsPerComponent(self.CGImage), 0,
                                             CGImageGetColorSpace(self.CGImage),
                                             CGImageGetBitmapInfo(self.CGImage));
    CGContextConcatCTM(ctx, transform);
    switch (self.imageOrientation) {
        case UIImageOrientationLeft:
        case UIImageOrientationLeftMirrored:
        case UIImageOrientationRight:
        case UIImageOrientationRightMirrored:
            // Grr...
            CGContextDrawImage(ctx, CGRectMake(0,0,self.size.height,self.size.width), self.CGImage);
            break;

        default:
            CGContextDrawImage(ctx, CGRectMake(0,0,self.size.width,self.size.height), self.CGImage);
            break;
    }

    // And now we just create a new UIImage from the drawing context
    CGImageRef cgimg = CGBitmapContextCreateImage(ctx);
    UIImage *img = [UIImage imageWithCGImage:cgimg];
    CGContextRelease(ctx);
    CGImageRelease(cgimg);
    return img;
}
```

这里用到了 CGAffineTransform 类来做矩阵变换，要注意一点是，合并两个 Transform 有两种方式，一种是 CGAffineTransformConcat(T1, T2)，它的执行顺序是 T1 -> T2，一种是 CGAffineTransformXXX(T1, T2)，它的执行顺序是 T2 -> T1，所以在这里要注意所有变换操作都是后加入的先执行。

fixOrientation 的基本思路是

* 如果 orientation 为 UIImageOrientationUp 则不需要变换
* 否则，首先对于镜像类 orientation 先恢复原样，变为非镜像
* 对于非镜像类 orientation，旋转回正常方向
* 根据旋转后的方向，利用 CoreGraphic 得到 UIImage 后返回

其中会有一些必要的移位操作，下面以 UIImageOrientationRightMirrored 为例进行具体操作说明

* 这是 orientation 为 UIImageOrientationRightMirrored 的图片

<img src="https://github.com/Yasic/FixImageOrientation/blob/master/SampleImage/Step01.png?raw=true" width=300>

* ```transform = CGAffineTransformScale(transform, -1, 1)``` 将图片进行镜像还原

<img src="https://github.com/Yasic/FixImageOrientation/blob/master/SampleImage/Step02.png?raw=true" width=300>

* ```transform = CGAffineTransformTranslate(transform, image.size.height, 0)```将图片移动到坐标原点

<img src="https://github.com/Yasic/FixImageOrientation/blob/master/SampleImage/Step03.png?raw=true" width=300>

* ```transform = CGAffineTransformRotate(transform, -M_PI_2)``` 将图片顺时针旋转 90 度

<img src="https://github.com/Yasic/FixImageOrientation/blob/master/SampleImage/Step04.png?raw=true" width=300>

* ```transform = CGAffineTransformTranslate(transform, 0, image.size.height)``` 将图片移动到坐标原点

<img src="https://github.com/Yasic/FixImageOrientation/blob/master/SampleImage/Step05.png?raw=true" width=300>

这里还要注意一点，在最后进行 drawImage 操作时代码如下

```objectivec
    switch (image.imageOrientation) {
        case UIImageOrientationLeft:
        case UIImageOrientationLeftMirrored:
        case UIImageOrientationRight:
        case UIImageOrientationRightMirrored:
            CGContextDrawImage(ctx, CGRectMake(0,0,image.size.height,image.size.width), image.CGImage);
            break;
            
        default:
            CGContextDrawImage(ctx, CGRectMake(0,0,image.size.width,image.size.height), image.CGImage);
            break;
    }
```

对于左右放置的图片，由于进行了旋转操作，因此最终进行 drawImage 时，rect 需要进行长宽变换。

而实际上，UIImage 的 drawInRect 方法已经实现了这一过程，并自动返回调整后的图片，且图片 orientation 为 UIImageOrientationUp。

> This method draws the entire image in the current graphics context, respecting the image’s orientation setting. In the default coordinate system, images are situated down and to the right of the origin of the specified rectangle. This method respects any transforms applied to the current graphics context, however.