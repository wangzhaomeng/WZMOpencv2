//
//  ViewController.m
//  WZMOpencv2
//
//  Created by Zhaomeng Wang on 2021/3/10.
//
/*
 官网下载地址：https://sourceforge.net/projects/opencvlibrary/
 需要将.m文件改为.mm
 引入OpenCV相关头文件
 OpenCV相关的头文件必须在 #import "ViewController.h"之前导入，否则连接错误
 
 */

#ifdef __cplusplus

#include <opencv2/imgproc/imgproc_c.h>
#import <opencv2/opencv.hpp>

#endif

#import "ViewController.h"

struct WZMCompareResult {
    double value1;
    double value2;
    double result;
};

@interface ViewController ()

@end

@implementation ViewController

- (void)viewDidLoad {
    [super viewDidLoad];
    
    UIImage *image1 = [UIImage imageNamed:@"IMG_0856"];
    UIImage *image2 = [UIImage imageNamed:@"IMG_0857"];
    
    UIImage *image = [self.class getLongImage:image1 otherImage:image2];
    
    UIImageView *imageView = [[UIImageView alloc] initWithFrame:self.view.bounds];
    imageView.image = image;
    imageView.contentMode = UIViewContentModeScaleAspectFit;
    [self.view addSubview:imageView];
}

- (void)touchesBegan:(NSSet<UITouch *> *)touches withEvent:(UIEvent *)event {
    UIImage *smaImage = [UIImage imageNamed:@"meinv_1_small"];
    UIImage *bigImage = [UIImage imageNamed:@"p_meinv_0_mix"];
    
    IplImage *iplimage1 = [self.class convertToIplImage:smaImage];
    IplImage *iplimage2 = [self.class convertToIplImage:bigImage];
    
    double rst = [self.class CompareHistWithSmallIpl:iplimage1 withBigIplImg:iplimage2];
    cvReleaseImage(&iplimage1);
    cvReleaseImage(&iplimage2);
    NSLog(@"%@",@(rst));
}

#pragma mark - 拼长图
+ (UIImage *)getLongImage:(UIImage *)image otherImage:(UIImage *)otherImage {
    IplImage *lmg1 = [self convertToIplImage:image];
    IplImage *lmg2 = [self convertToIplImage:otherImage];
    WZMCompareResult rst = [self longCompareIpl:lmg1 otherIpl:lmg2];
    if (rst.result <= 0.01) {
        //匹配成功
        IplImage *clmg1 = [self cropImage:lmg1 rect:CGRectMake(0.0, 0.0, lmg1->width, rst.value1)];
        IplImage *clmg2 = [self cropImage:lmg2 rect:CGRectMake(0.0, rst.value2, lmg2->width, (lmg2->height-rst.value2))];
        UIImage *cimg1 = [self convertToUIImage:clmg1];
        UIImage *cimg2 = [self convertToUIImage:clmg2];
        cvReleaseImage(&clmg1);
        cvReleaseImage(&clmg2);
        return [self getImageByImages:@[cimg1,cimg2] horizontal:NO];
    }
    cvReleaseImage(&lmg1);
    cvReleaseImage(&lmg2);
    return nil;
}

+ (WZMCompareResult)longCompareIpl:(IplImage*)srcIpl otherIpl:(IplImage*)srcIpl1 {
    double dy = 1;
    double dh = 500.0;//(srcIpl->height)/10.0;
    WZMCompareResult dbRst = {0.0, 0.0, 1.0};
    for (double y=(srcIpl->height-dh); y>0; y-=dy) {
        //第一张图片区5个像素的高度
        IplImage *dImage = [self cropImage:srcIpl rect:CGRectMake(0.0, y, srcIpl->width, dh)];
        for (double y2=0; y2<srcIpl1->height; y2++) {
            IplImage *dImage2 = [self cropImage:srcIpl1 rect:CGRectMake(0, y2, srcIpl1->width, dh)];
            double rst = [self CompareHist:dImage withParam2:dImage2];
            cvReleaseImage(&dImage2);
            if (dbRst.result < 0.01) {
                if (rst > 0.01) {
                    return {y, y2, dbRst.result};
                }
            }
            if (rst < dbRst.result) {
                dbRst = {y, y2, rst};
                NSLog(@"%@==%@==%@",@(dbRst.value1),@(dbRst.value2),@(dbRst.result));
            }
            if (dbRst.result < 0.05) {
                dy = 1;
            }
            else {
                dy = dh/10.0;
            }
        }
        cvReleaseImage(&dImage);
    }
    return dbRst;
}

+ (BOOL)isImage:(UIImage *)image1 likeImage:(UIImage *)image2 {
    IplImage *iplimage1 = [self convertToIplImage:image1];
    IplImage *iplimage2 = [self convertToIplImage:image2];
    double sililary = [self ComparePPKHist:iplimage1 withParam2:iplimage2];
    if (sililary < 0.3) {
        return YES;
    }
    return NO;
}

+ (double)ComparePPKHist:(IplImage*)srcIpl withParam2:(IplImage*)srcIpl1 {
    if (srcIpl->width==srcIpl1->width && srcIpl->height==srcIpl1->height) {
        return [self CompareHist:srcIpl withParam2:srcIpl1];
    }
    else if (srcIpl->width<srcIpl1->width && srcIpl->height==srcIpl1->height) {
        return [self CompareHistWithSmallWidthIpl:srcIpl withBigWidthIplImg:srcIpl1];
    }
    else if (srcIpl->width>srcIpl1->width && srcIpl->height==srcIpl1->height) {
        return [self CompareHistWithSmallWidthIpl:srcIpl1 withBigWidthIplImg:srcIpl];
    }
    else if (srcIpl->width==srcIpl1->width && srcIpl->height<srcIpl1->height) {
        return [self CompareHistWithSmallHeightIpl:srcIpl withBigHeightIplImg:srcIpl1];
    }
    else if (srcIpl->width==srcIpl1->width && srcIpl->height>srcIpl1->height) {
        return [self CompareHistWithSmallHeightIpl:srcIpl1 withBigHeightIplImg:srcIpl];
    }
    else if (srcIpl->width<srcIpl1->width && srcIpl->height<srcIpl1->height) {
        return [self CompareHistWithSmallIpl:srcIpl withBigIplImg:srcIpl1];
    }
    else if (srcIpl->width>srcIpl1->width && srcIpl->height>srcIpl1->height) {
        return [self CompareHistWithSmallIpl:srcIpl1 withBigIplImg:srcIpl];
    }
    return 1.f;
}

+ (double)CompareHistWithSmallWidthIpl:(IplImage*)srcIpl withBigWidthIplImg:(IplImage*)srcIpl1 {
    //当前匹配结果，越接近于0.0匹配度越高
    double dbRst=1.0;
    //匹配结果，-1表示正在匹配，0表示匹配失败，1表示匹配成功
    int tfFound = -1;
    //裁剪后的图片
    IplImage *cropImage;
    for (int j=0; j<srcIpl1->width-srcIpl->width; j++) {
        //裁剪图片
        cvSetImageROI(srcIpl1, cvRect(j, 0, srcIpl->width, srcIpl->height));
        cropImage = cvCreateImage(cvGetSize(srcIpl), IPL_DEPTH_8U, 3);
        cvCopy(srcIpl1, cropImage);
        cvResetImageROI(srcIpl1);
        //匹配图片
        double dbRst1 =[self CompareHist:srcIpl withParam2:cropImage];
        cvReleaseImage(&cropImage);
        printf("匹配结果为:%f\n",dbRst1);
        if (dbRst1<=0.01) {
            //匹配成功
            tfFound = 1;
            break;
        }
        else if(dbRst==1.0 || dbRst1<dbRst) {
            //本次匹配有进步，更新结果
            dbRst = dbRst1;
        }
    }
    return dbRst;
}

+ (double)CompareHistWithSmallHeightIpl:(IplImage*)srcIpl withBigHeightIplImg:(IplImage*)srcIpl1 {
    //当前匹配结果，越接近于0.0匹配度越高
    double dbRst=1.0;
    //匹配结果，-1表示正在匹配，0表示匹配失败，1表示匹配成功
    int tfFound = -1;
    //裁剪后的图片
    IplImage *cropImage;
    for (int j=0; j<srcIpl1->height-srcIpl->height; j++) {
        //裁剪图片
        cvSetImageROI(srcIpl1, cvRect(0, j, srcIpl->height, srcIpl->height));
        cropImage = cvCreateImage(cvGetSize(srcIpl), IPL_DEPTH_8U, 3);
        cvCopy(srcIpl1, cropImage);
        cvResetImageROI(srcIpl1);
        //匹配图片
        double dbRst1 =[self CompareHist:srcIpl withParam2:cropImage];
        cvReleaseImage(&cropImage);
        printf("匹配结果为:%f\n",dbRst1);
        if (dbRst1<=0.01) {
            //匹配成功
            tfFound = 1;
            break;
        }
        else if(dbRst==1.0 || dbRst1<dbRst) {
            //本次匹配有进步，更新结果
            dbRst = dbRst1;
        }
    }
    return dbRst;
}

+ (double)CompareHistWithSmallIpl:(IplImage*)srcIpl withBigIplImg:(IplImage*)srcIpl1 {
    //当前匹配结果，越接近于0.0匹配度越高
    double dbRst=1.0;
    //遍历移动偏移量
    int dx = 1, dy = 1;
    //遍历方式：先竖后横
    for (int x=0; x<srcIpl1->width-srcIpl->width; x+=dx) {
        for (int y=0; y<srcIpl1->height-srcIpl->height; y+=dy) {
            IplImage *cropImage = [self cropImage:srcIpl1 rect:CGRectMake(x, y, srcIpl->width, srcIpl->height)];
            double rst = [self CompareHist:srcIpl withParam2:cropImage];
            cvReleaseImage(&cropImage);
            //匹配结果达标
            if (dbRst < 0.01) {
                if (rst > 0.01) {
                    return dbRst;
                }
            }
            //匹配结果有进步
            if (rst < dbRst) {
                dbRst = rst;
                NSLog(@"%@==%@==%@",@(x),@(y),@(rst));
            }
            //匹配度过低时快速执行
            if (dbRst < 0.05) {
                dx = 1;
                dy = 1;
            }
            else {
                dx = (srcIpl->width)/10.0;
                dy = (srcIpl->height)/10.0;
            }
        }
    }
    return dbRst;
}

// 多通道彩色图片的直方图比对
+ (double)CompareHist:(IplImage*)image1 withParam2:(IplImage*)image2 {
    if (image1 == NULL || image2 == NULL) return 1.0;
    int hist_size = 256;
    //float range[] = {0,255};
    IplImage *gray_plane = cvCreateImage(cvGetSize(image1), 8, 1);
    cvCvtColor(image1, gray_plane, CV_BGR2GRAY);
    CvHistogram *gray_hist = cvCreateHist(1, &hist_size, CV_HIST_ARRAY);
    cvCalcHist(&gray_plane, gray_hist);
    IplImage *gray_plane2 = cvCreateImage(cvGetSize(image2), 8, 1);
    cvCvtColor(image2, gray_plane2, CV_BGR2GRAY);
    CvHistogram *gray_hist2 = cvCreateHist(1, &hist_size, CV_HIST_ARRAY);
    cvCalcHist(&gray_plane2, gray_hist2);
    double rst = cvCompareHist(gray_hist, gray_hist2, CV_COMP_BHATTACHARYYA);
    cvReleaseImage(&gray_plane);
    cvReleaseHist(&gray_hist);
    cvReleaseImage(&gray_plane2);
    cvReleaseHist(&gray_hist2);
    return rst;
}

// 单通道彩色图片的直方图
+ (double)CompareHistSignle:(IplImage*)image1 withParam2:(IplImage*)image2 {
    int hist_size = 256;
    //float range[] = {0,255};
    CvHistogram *gray_hist = cvCreateHist(1, &hist_size, CV_HIST_ARRAY);
    cvCalcHist(&image1, gray_hist);
    CvHistogram *gray_hist2 = cvCreateHist(1, &hist_size, CV_HIST_ARRAY);
    cvCalcHist(&image2, gray_hist2);
    double rst = cvCompareHist(gray_hist, gray_hist2, CV_COMP_BHATTACHARYYA);
    cvReleaseHist(&gray_hist);
    cvReleaseHist(&gray_hist2);
    return rst;
}

// 进行肤色检测
+ (void)SkinDetect:(IplImage*)src withParam:(IplImage*)dst {
    // 创建图像头
    IplImage* hsv = cvCreateImage(cvGetSize(src), IPL_DEPTH_8U, 3);//用于存图像的一个中间变量，是用来分通道用的，分成hsv通道
    IplImage* tmpH1 = cvCreateImage( cvGetSize(src), IPL_DEPTH_8U, 1);//通道的中间变量，用于肤色检测的中间变量
    IplImage* tmpS1 = cvCreateImage(cvGetSize(src), IPL_DEPTH_8U, 1);
    IplImage* tmpH2 = cvCreateImage(cvGetSize(src), IPL_DEPTH_8U, 1);
    IplImage* tmpS2 = cvCreateImage(cvGetSize(src), IPL_DEPTH_8U, 1);
    IplImage* tmpH3 = cvCreateImage(cvGetSize(src), IPL_DEPTH_8U, 1);
    IplImage* tmpS3 = cvCreateImage(cvGetSize(src), IPL_DEPTH_8U, 1);
    IplImage* H = cvCreateImage( cvGetSize(src), IPL_DEPTH_8U, 1);
    IplImage* S = cvCreateImage( cvGetSize(src), IPL_DEPTH_8U, 1);
    IplImage* V = cvCreateImage( cvGetSize(src), IPL_DEPTH_8U, 1);
    IplImage* src_tmp1=cvCreateImage(cvGetSize(src),8,3);
    // 高斯模糊
    cvSmooth(src,src_tmp1,CV_GAUSSIAN,3,3); //高斯模糊
    // hue色度，saturation饱和度，value纯度
    cvCvtColor(src_tmp1, hsv, CV_BGR2HSV );//颜色转换
    cvSplit(hsv,H,S,V,0);//分为3个通道
    /*********************肤色检测部分**************/
    cvInRangeS(H,cvScalar(0.0,0.0,0,0),cvScalar(20.0,0.0,0,0),tmpH1);
    cvInRangeS(S,cvScalar(75.0,0.0,0,0),cvScalar(200.0,0.0,0,0),tmpS1);
    cvAnd(tmpH1,tmpS1,tmpH1,0);
    // Red Hue with Low Saturation
    // Hue 0 to 26 degree and Sat 20 to 90
    cvInRangeS(H,cvScalar(0.0,0.0,0,0),cvScalar(13.0,0.0,0,0),tmpH2);
    cvInRangeS(S,cvScalar(20.0,0.0,0,0),cvScalar(90.0,0.0,0,0),tmpS2);
    cvAnd(tmpH2,tmpS2,tmpH2,0);
    // Red Hue to Pink with Low Saturation
    // Hue 340 to 360 degree and Sat 15 to 90
    cvInRangeS(H,cvScalar(170.0,0.0,0,0),cvScalar(180.0,0.0,0,0),tmpH3);
    cvInRangeS(S,cvScalar(15.0,0.0,0,0),cvScalar(90.,0.0,0,0),tmpS3);
    cvAnd(tmpH3,tmpS3,tmpH3,0);
    // Combine the Hue and Sat detections
    cvOr(tmpH3,tmpH2,tmpH2,0);
    cvOr(tmpH1,tmpH2,tmpH1,0);
    cvCopy(tmpH1,dst);
    cvReleaseImage(&hsv);
    cvReleaseImage(&tmpH1);
    cvReleaseImage(&tmpS1);
    cvReleaseImage(&tmpH2);
    cvReleaseImage(&tmpS2);
    cvReleaseImage(&tmpH3);
    cvReleaseImage(&tmpS3);
    cvReleaseImage(&H);
    cvReleaseImage(&S);
    cvReleaseImage(&V);
    cvReleaseImage(&src_tmp1);
}

/// UIImage类型转换为IPlImage类型
+ (IplImage*)convertToIplImage:(UIImage*)image {
    CGImageRef imageRef = image.CGImage;
    CGColorSpaceRef colorSpace = CGColorSpaceCreateDeviceRGB();
    IplImage *iplImage = cvCreateImage(cvSize(image.size.width, image.size.height), IPL_DEPTH_8U, 4);
    CGContextRef contextRef = CGBitmapContextCreate(iplImage->imageData, iplImage->width, iplImage->height, iplImage->depth, iplImage->widthStep, colorSpace, kCGImageAlphaPremultipliedLast|kCGBitmapByteOrderDefault);
    CGContextDrawImage(contextRef, CGRectMake(0, 0, image.size.width, image.size.height), imageRef);
    CGContextRelease(contextRef);
    CGColorSpaceRelease(colorSpace);
    IplImage *ret = cvCreateImage(cvGetSize(iplImage), IPL_DEPTH_8U, 3);
    cvCvtColor(iplImage, ret, CV_RGB2BGR);
    cvReleaseImage(&iplImage);
    return ret;
}

/// IplImage类型转换为UIImage类型
+ (UIImage*)convertToUIImage:(IplImage*)image {
    cvCvtColor(image, image, CV_BGR2RGB);
    CGColorSpaceRef colorSpace = CGColorSpaceCreateDeviceRGB();
    NSData *data = [NSData dataWithBytes:image->imageData length:image->imageSize];
    CGDataProviderRef provider = CGDataProviderCreateWithCFData((CFDataRef)data);
    CGImageRef imageRef = CGImageCreate(image->width, image->height, image->depth, image->depth * image->nChannels, image->widthStep, colorSpace, kCGImageAlphaNone | kCGBitmapByteOrderDefault, provider, NULL, false, kCGRenderingIntentDefault);
    UIImage *ret = [UIImage imageWithCGImage:imageRef];
    CGImageRelease(imageRef);
    CGDataProviderRelease(provider);
    CGColorSpaceRelease(colorSpace);
    return ret;
}

//剪裁图片
+ (IplImage *)cropImage:(IplImage *)image rect:(CGRect)rect {
    cvSetImageROI(image, cvRect(rect.origin.x, rect.origin.y, rect.size.width, rect.size.height));
    IplImage *cropImage = cvCreateImage(cvGetSize(image), IPL_DEPTH_8U, 3);
    cvCopy(image, cropImage);
    cvResetImageROI(image);
    return cropImage;
}

+ (UIImage *)getImage:(UIImage *)image scale:(CGFloat)scale {
    CGSize size = CGSizeMake(ceil(image.size.width*scale),ceil(image.size.height*scale));
    UIGraphicsBeginImageContext(size);
    [image drawInRect:CGRectMake(0, 0, size.width, size.height)];
    UIImage *scaledImage = UIGraphicsGetImageFromCurrentImageContext();
    UIGraphicsEndImageContext();
    return scaledImage;
}

+ (UIImage *)getImageByImages:(NSArray<UIImage *> *)images horizontal:(BOOL)horizontal {
    UIImage *fImage = images.firstObject;
    if (horizontal) {
        //横向
        CGSize size = CGSizeMake(fImage.size.width*images.count, fImage.size.height);
        UIGraphicsBeginImageContextWithOptions(size, NO, [UIScreen mainScreen].scale);
        for (NSInteger i = 0; i < images.count; i ++) {
            UIImage *image = [images objectAtIndex:i];
            [image drawInRect:CGRectMake(i*fImage.size.width, 0, fImage.size.width, fImage.size.height)];
        }
    }
    else {
        //纵向
        CGSize size = CGSizeMake(fImage.size.width, fImage.size.height*images.count);
        UIGraphicsBeginImageContextWithOptions(size, NO, [UIScreen mainScreen].scale);
        for (NSInteger i = 0; i < images.count; i ++) {
            UIImage *image = [images objectAtIndex:i];
            [image drawInRect:CGRectMake(0, i*fImage.size.height, fImage.size.width, fImage.size.height)];
        }
    }
    UIImage *scaledImage = UIGraphicsGetImageFromCurrentImageContext();
    UIGraphicsEndImageContext();
    return scaledImage;
}

@end
