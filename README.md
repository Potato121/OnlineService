# OnlineService
#H5与原生的交互
包括H5和原生交互的功能：

- 语音识别、语音合成
- 地图导航
- 分享


**如果需要使用，需要在Info.plist里面添加如下内容：**

- LSApplicationQueriesSchemes下添加以下2项，用于打开地图导航

~~~
<string>iosamap</string>
<string>baidumap</string>
~~~
- info.plist添加以下几项的授权

~~~
Privacy - Media Library Usage Description
Privacy - Camera Usage Description
Privacy - Location Always Usage Description
Privacy - Location Usage Description
Privacy - Location When In Use Usage Description
Privacy - Microphone Usage Description
Privacy - Photo Library Usage Description
Privacy - Speech Recognition Usage Description
~~~

---
**安装方式**

- 下载源码安装，需要导入源代码以及`OnlineService.bundle`
- 通过Cocoapods安装， 在`podfile`里面添加如下命令，`pod "OnlineService"`

---

### 联系方式
1228781716@qq.com

### 网址
www.hedy.ltd


