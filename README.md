##分享一个无侵入埋点方案。

demo地址: https://github.com/AutoJiang/TrackDemo.git

使用无侵入埋点方案的好处就是能将埋点代码和业务代码解耦。

然而很多无侵入埋点都是hook系统的方式去，比如一些第三方埋点库，拥有自动埋点的功能。但是这个难以满足我们项目自定义化埋点的需求。

通过该无侵入埋点，可以做到将整个项目所有的业务埋点逻辑都写入在一个文件里。

![image.png](https://upload-images.jianshu.io/upload_images/5353063-5c16a29041456c3f.png?imageMogr2/auto-orient/strip%7CimageView2/2/w/1240)


![image.png](https://upload-images.jianshu.io/upload_images/5353063-c7ef5b12fa5dfd81.png?imageMogr2/auto-orient/strip%7CimageView2/2/w/1240)

并且这个文件不会与任何业务代码耦合（我们看看引入的头文件）
![image.png](https://upload-images.jianshu.io/upload_images/5353063-b59099f067e7e7d2.png?imageMogr2/auto-orient/strip%7CimageView2/2/w/1240)

具体细节请参考实现。
由于无侵入埋点的方案是基于当前项目中存在的埋点业务特点，定制化编写对应的格式，所以不太适合做成基础组件，因此楼主只给了一个demo，供大家参考。

####原理:

1. 基于运行时交换方法，以及动态添加方法的方式，hook要埋点的对象的方法，然后插入埋点代码。
2. 可通过配置的方式生成插入代码。
3. 动态下发json文件的方式，动态添加埋点。


目前可支持两种方式，添加埋点。

####方式一:

1. 在该处添加要交换的对象、方法，以及替换方法 （hook_className_methodName:）

![image.png](https://upload-images.jianshu.io/upload_images/5353063-e191a1bd7524d348.png?imageMogr2/auto-orient/strip%7CimageView2/2/w/1240)



2. 在该处添加交换方法。（注：必须保证参数一致）

![image.png](https://upload-images.jianshu.io/upload_images/5353063-7f7093455a04cfc2.png?imageMogr2/auto-orient/strip%7CimageView2/2/w/1240)


3. 可通过KVC的方式来获取对象属性。（因为 self 为被hook的class，理论上可以获取self的任何属性）
例如：
![image.png](https://upload-images.jianshu.io/upload_images/5353063-029c06f7eb5b0787.png?imageMogr2/auto-orient/strip%7CimageView2/2/w/1240)

####方式二:
通过配置的方式添加埋点，在tracker.json下添加如下配置，即可添加埋点。

![image.png](https://upload-images.jianshu.io/upload_images/5353063-a587c65b901d9798.png?imageMogr2/auto-orient/strip%7CimageView2/2/w/1240)

####注意事项：

1. hookClass为hook的对象。

2. hookMethod为hook方法。

3. events为添加的事件，为数组类型。代表这一句代码里面存在多个埋点。types , refers数组个数必须和events一致。

4. "#0"代表取第一个参数，"#1"代表取第二个参数，"#2"代表取第三个参数，以此类推。

5. 可通过self.articleInfo.articleBase.articleId的方式来获取成员属性。
6. 该方式目前只支持对象类型的参数，不支持基础数据类型（方式一不受限制）。


