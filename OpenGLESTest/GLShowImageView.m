
//
//  GLShowImageView.m
//  OpenGLESTest
//
//  Created by 王勇 on 2018/11/8.
//  Copyright © 2018年 王勇. All rights reserved.
//

#import "GLShowImageView.h"
#import <OpenGLES/ES2/gl.h>

#define VSH @"attribute vec4 position;\
attribute vec2 textCoordinate;\
uniform mat4 rotateMatrix;\
varying lowp vec2 varyTextCoord;\
void main()\
{\
varyTextCoord = textCoordinate;\
vec4 vPos = position;\
vPos = vPos * rotateMatrix;\
gl_Position = vPos;\
}"

#define FSH @"varying lowp vec2 varyTextCoord;\
uniform sampler2D colorMap;\
void main()\
{\
gl_FragColor = texture2D(colorMap, varyTextCoord);\
}"

#pragma clang diagnostic push
#pragma clang diagnostic ignored "-Wdeprecated-declarations"

@interface GLShowImageView()

@property (nonatomic , strong) EAGLContext* context;
@property (nonatomic , strong) CAEAGLLayer* myEagLayer;
@property (nonatomic , assign) GLuint       myProgram;


@property (nonatomic , assign) GLuint viewRenderbuffer;
@property (nonatomic , assign) GLuint viewFramebuffer;

- (void)setupLayer;

@end

@implementation GLShowImageView

// Releases resources when they are not longer needed.
- (void)dealloc
{
    NSLog(@"dealloc");
    // Destroy framebuffers and renderbuffers
    if (_viewFramebuffer) {
        glDeleteFramebuffers(1, &_viewFramebuffer);
        _viewFramebuffer = 0;
    }
    if (_viewRenderbuffer) {
        glDeleteRenderbuffers(1, &_viewRenderbuffer);
        _viewRenderbuffer = 0;
    }
    
    // tear down context
    if ([EAGLContext currentContext] == self.context)
        [EAGLContext setCurrentContext:nil];
}
+ (Class)layerClass {
    
    return [CAEAGLLayer class];
}
- (void)layoutSubviews {
    
    [self setupLayer];
    
    [self setupContext];
    
    [self destoryRenderAndFrameBuffer];
    
    [self setupRenderBuffer];
    
    [self setupFrameBuffer];
    
    [self render];
}

- (void)render
{
    glClearColor(0.0, 1.0, 0.0, 1.0);
    
    glClear(GL_COLOR_BUFFER_BIT);
    
    CGFloat scale = [[UIScreen mainScreen] scale]; //获取视图放大倍数，可以把scale设置为1试试
    
    glViewport(0, 0, self.frame.size.width * scale, self.frame.size.height * scale); //设置视口大小
    
    GLuint position;
    
    GLuint textCoor;
    
    GLuint rotate ;
    
    //加载shader
    self.myProgram = [self loadShaders:VSH frag:FSH];
    //链接
    glLinkProgram(self.myProgram);
    
    GLint linkSuccess;
    
    glGetProgramiv(self.myProgram, GL_LINK_STATUS, &linkSuccess);
    
    if (linkSuccess == GL_FALSE) { //连接错误
        
        GLchar messages[256];
        
        glGetProgramInfoLog(self.myProgram, sizeof(messages), 0, &messages[0]);
        
        NSString *messageString = [NSString stringWithUTF8String:messages];
        
        NSLog(@"error%@", messageString);
        
        return ;
        
    }else {
        
        NSLog(@"link ok");
        
        glUseProgram(self.myProgram);
    }
    
    position = glGetAttribLocation(self.myProgram, "position");
    
    textCoor = glGetAttribLocation(self.myProgram, "textCoordinate");
    
    //获取shader里面的变量，这里记得要在glLinkProgram后面，后面，后面！
    rotate = glGetUniformLocation(self.myProgram, "rotateMatrix");

    //前三个是顶点坐标， 后面两个是纹理坐标
    GLfloat attrArr[] =
    {
        
        -1.0f, 1.0f, 0.f,     0.0f, 1.0f,//左上
        1.0f, -1.0f, 0.f,     1.0f, 0.0f,//右下
        -1.0f, -1.0f, 0.f,    0.0f, 0.0f,//左下
        1.0f, 1.0f, 0.f,      1.0f, 1.0f,//右上
        1.0f, -1.0f, 0.f,     1.0f, 0.0f,//右下
        -1.0f, 1.0f, 0.f,     0.0f, 1.0f,//左上
    };
    
    GLuint vertexBuffer;
    
    glGenBuffers(1, &vertexBuffer);
    // 绑定vertexBuffer到GL_ARRAY_BUFFER目标
    glBindBuffer(GL_ARRAY_BUFFER, vertexBuffer);
    
    glBufferData(GL_ARRAY_BUFFER, sizeof(attrArr), attrArr, GL_DYNAMIC_DRAW);
    
    glVertexAttribPointer(position, 3, GL_FLOAT, GL_FALSE, sizeof(GLfloat) * 5, NULL);
    
    glVertexAttribPointer(textCoor, 2, GL_FLOAT, GL_FALSE, sizeof(GLfloat) * 5, (float *)NULL + 3);
    
    glEnableVertexAttribArray(position);
    
    glEnableVertexAttribArray(textCoor);
    //加载纹理
    if (![self setupTexture:[UIImage imageNamed:@"wy_colorSelect"].CGImage]) {
        
        return;
    }
    
    //z轴旋转矩阵
    GLfloat zRotation[16] = {
        1.0,0,0,0,
        0,-1.0,0,0,
        0,0,1.0,0,
        0,0,0,2.0
    };

    //设置旋转矩阵
    glUniformMatrix4fv(rotate, 1, GL_FALSE, zRotation);

    glDrawArrays(GL_TRIANGLES, 0, 6);
    
    [self.context presentRenderbuffer:GL_RENDERBUFFER];
}

/**
 *  c语言编译流程：预编译、编译、汇编、链接
 *  glsl的编译过程主要有glCompileShader、glAttachShader、glLinkProgram三步；
 *  @param vert 顶点着色器
 *  @param frag 片元着色器
 *
 *  @return 编译成功的shaders
 */
- (GLuint)loadShaders:(NSString *)vert frag:(NSString *)frag {
    GLuint verShader, fragShader;
    GLint program = glCreateProgram();
    
    //编译
    [self compileShader:&verShader type:GL_VERTEX_SHADER file:vert];
    [self compileShader:&fragShader type:GL_FRAGMENT_SHADER file:frag];
    
    glAttachShader(program, verShader);
    glAttachShader(program, fragShader);
    
    
    //释放不需要的shader
    glDeleteShader(verShader);
    glDeleteShader(fragShader);
    
    return program;
}

- (void)compileShader:(GLuint *)shader type:(GLenum)type file:(NSString *)content {
    //读取字符串
    const GLchar* source = (GLchar *)[content UTF8String];
    
    *shader = glCreateShader(type);
    glShaderSource(*shader, 1, &source, NULL);
    glCompileShader(*shader);
}

- (void)setupLayer
{
    self.myEagLayer = (CAEAGLLayer*) self.layer;
    //设置放大倍数
    [self setContentScaleFactor:[[UIScreen mainScreen] scale]];
    
    // CALayer 默认是透明的，必须将它设为不透明才能让其可见
    self.myEagLayer.opaque = YES;
    
    // 设置描绘属性，在这里设置不维持渲染内容以及颜色格式为 RGBA8
    self.myEagLayer.drawableProperties = [NSDictionary dictionaryWithObjectsAndKeys:
                                          [NSNumber numberWithBool:NO], kEAGLDrawablePropertyRetainedBacking, kEAGLColorFormatRGBA8, kEAGLDrawablePropertyColorFormat, nil];
}


- (void)setupContext {
    // 指定 OpenGL 渲染 API 的版本，在这里我们使用 OpenGL ES 2.0
    EAGLRenderingAPI api = kEAGLRenderingAPIOpenGLES2;
    EAGLContext* context = [[EAGLContext alloc] initWithAPI:api];
    if (!context) {
        NSLog(@"Failed to initialize OpenGLES 2.0 context");
        exit(1);
    }
    
    // 设置为当前上下文
    if (![EAGLContext setCurrentContext:context]) {
        NSLog(@"Failed to set current OpenGL context");
        exit(1);
    }
    self.context = context;
}

- (void)setupRenderBuffer {
    GLuint buffer;
    glGenRenderbuffers(1, &buffer);
    self.viewRenderbuffer = buffer;
    glBindRenderbuffer(GL_RENDERBUFFER, self.viewRenderbuffer);
    // 为 颜色缓冲区 分配存储空间
    [self.context renderbufferStorage:GL_RENDERBUFFER fromDrawable:self.myEagLayer];
}


- (void)setupFrameBuffer {
    GLuint buffer;
    glGenFramebuffers(1, &buffer);
    self.viewFramebuffer = buffer;
    // 设置为当前 framebuffer
    glBindFramebuffer(GL_FRAMEBUFFER, self.viewFramebuffer);
    // 将 _colorRenderBuffer 装配到 GL_COLOR_ATTACHMENT0 这个装配点上
    glFramebufferRenderbuffer(GL_FRAMEBUFFER, GL_COLOR_ATTACHMENT0,
                              GL_RENDERBUFFER, self.viewRenderbuffer);
}

- (void)destoryRenderAndFrameBuffer
{
    glDeleteFramebuffers(1, &_viewFramebuffer);
    self.viewFramebuffer = 0;
    glDeleteRenderbuffers(1, &_viewRenderbuffer);
    self.viewRenderbuffer = 0;
}
- (GLuint)setupTexture:(CGImageRef)imageRef
{
    // 1获取图片的CGImageRef
    CGImageRef spriteImage = imageRef;
    
    if (!spriteImage) {
        
        return 0;
    }
    
    // 2 读取图片的大小
    size_t width = CGImageGetWidth(spriteImage);
    size_t height = CGImageGetHeight(spriteImage);
    
    GLubyte * spriteData = (GLubyte *) calloc(width * height * 4, sizeof(GLubyte)); //rgba共4个byte
    
    CGContextRef spriteContext = CGBitmapContextCreate(spriteData, width, height, 8, width*4,
                                                       CGImageGetColorSpace(spriteImage), kCGImageAlphaPremultipliedLast);
    
    // 3在CGContextRef上绘图
    CGContextDrawImage(spriteContext, CGRectMake(0, 0, width, height), spriteImage);
    
    CGContextRelease(spriteContext);
    
    // 4绑定纹理到默认的纹理ID（这里只有一张图片，故而相当于默认于片元着色器里面的colorMap，如果有多张图不可以这么做）
    glBindTexture(GL_TEXTURE_2D, 0);
    
    
    glTexParameteri( GL_TEXTURE_2D, GL_TEXTURE_MIN_FILTER, GL_LINEAR );
    glTexParameteri( GL_TEXTURE_2D, GL_TEXTURE_MAG_FILTER, GL_LINEAR );
    glTexParameteri( GL_TEXTURE_2D, GL_TEXTURE_WRAP_S, GL_CLAMP_TO_EDGE);
    glTexParameteri( GL_TEXTURE_2D, GL_TEXTURE_WRAP_T, GL_CLAMP_TO_EDGE);
    
    float fw = width, fh = height;
    glTexImage2D(GL_TEXTURE_2D, 0, GL_RGBA, fw, fh, 0, GL_RGBA, GL_UNSIGNED_BYTE, spriteData);
    
    glBindTexture(GL_TEXTURE_2D, 0);
    
    free(spriteData);
    return 1;
}
@end
#pragma clang diagnostic pop
