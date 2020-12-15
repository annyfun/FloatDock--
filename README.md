# FloatDock : Mac 悬浮 Dock

#### 版本:2.4
1. 增加了状态栏icon功能.

#### 版本:1.5
1. 创建多个浮动 dock, 可以右键增加 APP、把 APP 拖动到 dock 上、从收藏列表中添加 APP。
2. 收藏 APP 并且为 APP 创建全局快捷键， 支持单个快捷键打开多个 APP。
3. ⌘↑和⌘↓调整所有 dock 透明度，最低为0，背景透明度初始值为0.5。⌘F打开收藏页面。
4. 生成 Mac APP 置顶代码，例如右键正在运行状态中的 Simulator，点击 ‘置顶LLDB’ ，然后打开terminal，输入 'lldb' 回车，粘贴回车，输入 Mac 密码回车。然后 Simulator 就可以置顶运行了。

代码如下：
```
lldb // 进入lldb 
process attach --pid 20993 // 获取指定的线程
e NSApplication $app = [NSApplication sharedApplication]; //获取APP
e NSWindow $win = $app.windows[0];// 获取指定的window
e [$win setLevel: 3];// 置顶window
exit // 退出lldb
y  // 确认
```
假如有多个正在运行的 Simulator window， 注意修改 ‘e NSWindow $win = $app.windows[0]; ’ 中的0对应指定的 window 序号即可。

5. 暂时不支持 Mac10.14，手边没有测试机器。

#### 使用截图
<p> <img src="https://github.com/popor/FloatDock/blob/master/info/info1.png" 
width="100%" height="100%"> </p>
<p> <img src="https://github.com/popor/FloatDock/blob/master/info/info2.png" width="100%" height="100%"> </p>
<p> <img src="https://github.com/popor/FloatDock/blob/master/info/info3.png" width="100%" height="100%"> </p>
<p> <img src="https://github.com/popor/FloatDock/blob/master/info/info4.png" width="100%" height="100%"> </p>
<p> <img src="https://github.com/popor/FloatDock/blob/master/info/info5.png" width="100%" height="100%"> </p>
<p> <img src="https://github.com/popor/FloatDock/blob/master/info/info6.png" width="100%" height="100%"> </p>
