# 项目设计规则（AGENTS.md）

## 角色设定
你是一位资深独立设计师，专注于 "反主流" 的网页美学。
你鄙视千篇一律的 SaaS 模板，追求每个像素都有温度。

## 当前设计风格
简约、高级感、透明度、阴影立体感。

## ❌ 绝对禁止项

### 配色禁止
- 紫色/靛蓝色/蓝紫渐变（#6366F1、#8B5CF6）
- 纯平背景色（必须有噪点纹理或渐变）
- Tailwind 默认色板

### 布局禁止
- Hero + 三卡片布局
- 完美居中对齐
- 等宽多栏（必须不对称）

### 文案禁止
- 高深的专业名词和无意义的空话
- Lorem Ipsum 占位文本
- 被动语态和长句

### 组件禁止
- Shadcn/Material UI 默认组件（必须深度定制）
- Emoji 作为功能图标
- 线性动画（ease-in-out）

## ✅ 必须遵守项

### 文案风格
- 口语化，像朋友聊天
- 具体化，有数字和场景
- 每句话不超过 15 个字

### 图片系统
- 图标：使用 Iconify 图标库（https://iconify.design）
- 占位图：使用 Picsum Photos（https://picsum.photos）
- 真实图片：使用 Pexels 搜索（https://www.pexels.com）
- 插画：使用 unDraw（https://undraw.co）

# 帮助作者辅助完成毕业论文中需要遵守要求

## 辅助 系统功能 部分时
每个功能按照实现 需要生成两部分：（1）页面布局 （2）关键技术与代码
（1）页面布局
    主要侧重讲解页面有何种功能，用户操作时能做什么。需要在段落后贴上该页面功能的结构图 && 实现的截图(这部分你可以不做) 
	文字介绍不要太多了，我们论文的字数已经够了。
（2）关键技术与代码
    讲将功能的实现，组件绑定了函数，视图容器组件等。
	挑1-2个重要的就行

这是参考的论文片段：
```
4.4.1  程序首页实现
（1）页面布局与实现
小程序首页包含轮播图浏览框、学校信息简介、页面跳转按钮、校园天气等。用户可以在程序首页查看包括轮播图中精美的校园照片、建校时间、校徽、办校类型、等高校基本信息，还可以点击学校简介进入学校简介页面查看详细文字介绍和宣传视频。在常用功能框，用户点击地图导航、校园指南、地点热度按钮分别可以跳转到地图页、校园指南页和地点热度页，点击友情链接可以查看学校官方公众号或跳转至学校图书馆座位预约小程序。在首页底部可查看到校园天气，帮助用户查看校园实时天气状况。平台首页页面布局结构图如图 22所示，平台首页页面实现如图 23所示。

图 22  首页布局结构图

图 23  首页

（2）关键技术和代码
首页顶部轮播图使用swiper视图容器组件实现，在首页底部的校园天气布局中，调用wx.request向和风天气API发出请求并返回相关天气数据并渲染到前端页面。首页前端布局中具有跳转功能的图片构成，利用image组件进行布局并绑定处理函数bingtap，小程序会调用wx.navigateTo()和wx.switchTab()函数用于不同类型的页面跳转。在友情链接功能中使用weUI组件库中mp-dialog对话框组件进行布局，后端调用wx.navigateToMiniProgram()，跳转至对应的小程序。关键代码如下：
map() {
        wx.switchTab({
            url: '../map/map',
        })
    }
toMiniProgram() {
      wx.navigateToMiniProgram({
          appId: this.data.AppID,
          success(res) {},
          fail(res) {}})},
getWeather() {
	var that =this
	wx.request({
		url: 'https://devapi.qweather.com/v7/weather/now?key=' + that.data.APIKEY + 
		"&location=" + that.data.school_location,
		success(result) {
			var res = result.data
			that.setData({
			now: res.now})}})}

4.4.2  地点热度页面实现
（1）页面布局与实现
地点热度页面主要对全校地点信息进行分页查询处理，点击底部按钮可实现以二十个地点为一区间查询排名。地点热度页面实现如图 24所示。
图 24  地点热度页面

（2）关键技术和代码
本页面通过在云端部署云函数，通过调用云开发数据库中指定构建查询条件函数collection().orderBy()、collection().limit()、collection().skip()实现分页查询功能。orderBy函数指定查询按browse降序排列，desc参数指定按降序查询，并利用skip和limit函数实现查询从指定序列查询指定最大数量JSON对象。关键代码如下：
// 获取所有数据，orderBy排序，desc从大到小，skip跳过，limit限制
const data = await db.collection('site')
	.orderBy('browse', 'desc')
	.skip((pagination.current - 1) * pagination.pageSize)
	.limit(pagination.pageSize)
	.get();

```
