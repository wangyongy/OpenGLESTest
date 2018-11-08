//
//  LearnView.m
//  LearnOpenGLES
//
//  Created by 林伟池 on 16/3/11.
//  Copyright © 2016年 林伟池. All rights reserved.
//

#import "LearnView.h"
#import <OpenGLES/ES2/gl.h>

#define VSH @"attribute vec4 Position;\
attribute vec4 SourceColor;\
varying vec4 DestinationColor;\
void main(void) {\
    DestinationColor = SourceColor;\
    gl_Position = Position;\
}"

#define FSH @"varying lowp vec4 DestinationColor;\
void main(void) {\
    gl_FragColor = DestinationColor;\
}"

typedef struct {
    GLfloat x,y,z;
    GLfloat r,g,b;
} Vertex;

#pragma clang diagnostic push
#pragma clang diagnostic ignored "-Wdeprecated-declarations"
@interface LearnView()

/**   图案类型 0:三角形 1:矩形 2:圆形  */
@property(nonatomic,assign) NSInteger drawType;

/**  是否是空心  */
@property(nonatomic,assign) BOOL isHollow;

@property (nonatomic , strong) EAGLContext* context;
@property (nonatomic , strong) CAEAGLLayer* myEagLayer;
@property (nonatomic , assign) GLuint       myProgram;


@property (nonatomic , assign) GLuint viewRenderbuffer;
@property (nonatomic , assign) GLuint viewFramebuffer;

- (void)setupLayer;

@end

@implementation LearnView

- (void)change
{
    _drawType++;
    
    if (_drawType > 2) _drawType = 0;
    
    if (_drawType == 2){
        
        [self renderCircular];
        
        _isHollow = !_isHollow;
    }
    
    else [self render];
}
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

- (void)render {
    
    glClearColor(0, 1.0, 0.0, 1.0);
    
    glClear(GL_COLOR_BUFFER_BIT);
    
    CGFloat scale = [[UIScreen mainScreen] scale]; //获取视图放大倍数，可以把scale设置为1试试
    
    glViewport(0, 0, self.frame.size.width * scale, self.frame.size.height * scale); //设置视口大小

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
        
        NSLog(@"error:%@", messageString);
        
        return ;
        
    }else {
        
        NSLog(@"link ok");
        
        glUseProgram(self.myProgram); //成功便使用，避免由于未使用导致的的bug
    }

    GLuint position = glGetAttribLocation(self.myProgram, "Position");
    
    GLuint textCoor = glGetAttribLocation(self.myProgram, "SourceColor");

    const GLfloat Vertices[] = {
        -0.5f,-0.5f,0,0,0,0,// 左下，黑色
        0.5f,-0.5f,0,1,0,0, // 右下，红色
        0.5f,0.5f,0,0,1,0,  // 右上，绿色
        -0.5f,0.5f,0,0,0,1, // 左上，蓝色
    };

    // 索引数组，指定好了绘制三角形的方式
    // 与glDrawArrays(GL_TRIANGLE_STRIP, 0, 4);一样。
    const GLubyte Indices[] = {
        0,1,2, // 三角形0
        0,2,3  // 三角形1
    };
    
    GLuint vertexBuffer;

    glGenBuffers(1, &vertexBuffer);
    // 绑定vertexBuffer到GL_ARRAY_BUFFER目标
    glBindBuffer(GL_ARRAY_BUFFER, vertexBuffer);
    // 为VBO申请空间，初始化并传递数据
    glBufferData(GL_ARRAY_BUFFER, sizeof(Vertices), Vertices, GL_STATIC_DRAW);
    
    // 给_positionSlot传递vertices数据
    glVertexAttribPointer(position, 3, GL_FLOAT, GL_FALSE, sizeof(GLfloat) * 6, NULL);
    
    glEnableVertexAttribArray(position);
    
    // 取出Colors数组中的每个坐标点的颜色值，赋给_colorSlot
    glVertexAttribPointer(textCoor, 4, GL_FLOAT, GL_FALSE, sizeof(GLfloat) * 6, (float *)NULL + 3);
    
    glEnableVertexAttribArray(textCoor);

    if (_drawType == 1) {
        // Draw triangle
        if (_isHollow) glDrawArrays(GL_LINE_LOOP, 0, 4);   //GL_LINE_LOOP不带填充
        
        else  glDrawElements(GL_TRIANGLES, sizeof(Indices)/sizeof(Indices[0]), GL_UNSIGNED_BYTE, Indices);
    }else{

        glDrawArrays(_isHollow ? GL_LINE_LOOP : GL_TRIANGLES, 0, 3);   //GL_LINE_LOOP不带填充
    }

    [self.context presentRenderbuffer:GL_RENDERBUFFER];
}

- (void)renderCircular {
    
    glClearColor(0, 1.0, 1.0, 1.0);
    
    glClear(GL_COLOR_BUFFER_BIT);
 
    CGFloat scale = [[UIScreen mainScreen] scale]; //获取视图放大倍数，可以把scale设置为1试试
    
    glViewport(0, 0, self.frame.size.width * scale, self.frame.size.height * scale); //设置视口大小
    
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
        
        NSLog(@"error:%@", messageString);
        
        return ;
        
    }else {
        
        NSLog(@"link ok");
        
        glUseProgram(self.myProgram); //成功便使用，避免由于未使用导致的的bug
    }
    
    GLuint position = glGetAttribLocation(self.myProgram, "Position");
    
    GLuint textCoor = glGetAttribLocation(self.myProgram, "SourceColor");
    
    GLint vertCount = 101; //分割份数
    
    Vertex vertext[vertCount];
 
    float delta = 2.0*M_PI/vertCount;
    
    float a = 0.8; //水平方向的半径
    float b = a * self.frame.size.width / self.frame.size.height;
    
    for (int i = 0; i < vertCount; i++) {
        GLfloat x = a * cos(delta * i);
        GLfloat y = b * sin(delta * i);
        GLfloat z = 0.0;
        vertext[i] = (Vertex){x, y, z, x, y, x+y};
        
        printf("%f , %f\n", x, y);
    }

    GLuint vertexBuffer;
    
    glGenBuffers(1, &vertexBuffer);
    // 绑定vertexBuffer到GL_ARRAY_BUFFER目标
    glBindBuffer(GL_ARRAY_BUFFER, vertexBuffer);
    // 为VBO申请空间，初始化并传递数据
    glBufferData(GL_ARRAY_BUFFER, sizeof(vertext), vertext, GL_STATIC_DRAW);
    
    // 给_positionSlot传递vertices数据
    glVertexAttribPointer(position, 3, GL_FLOAT, GL_FALSE, sizeof(GLfloat) * 6, NULL);
    
    glEnableVertexAttribArray(position);
    
    // 取出Colors数组中的每个坐标点的颜色值，赋给_colorSlot
    glVertexAttribPointer(textCoor, 4, GL_FLOAT, GL_FALSE, sizeof(GLfloat) * 6, (float *)NULL + 3);
    
    glEnableVertexAttribArray(textCoor);
    
    glDrawArrays(_isHollow ? GL_LINE_LOOP : GL_TRIANGLE_FAN, 0, vertCount);//GL_LINE_LOOP 不带填充
    
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
@end
#pragma clang diagnostic pop
