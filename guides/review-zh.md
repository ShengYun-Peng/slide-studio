# 本地 review 导航

这个项目把我们做 defense 时有效的做法拆成三层：**讲故事和写讲稿的方法、可复用的版式、能重新渲染的动画场景**。`my-project` 是以后每次真正做 slides 的工作目录。

先看 [START_HERE](../START_HERE.md)，再运行 `python3 studio.py doctor` 和 `python3 studio.py catalog`。新 agent 只需要这个项目、shell，以及你提供的素材；不需要旧 defense folder 或旧聊天。

建议重点 review：

- **风格和版式：** [visual-design.md](visual-design.md)。字号、深色背景、color code、目录页层级、paper 首页、头像和图表都写在这里。它们是可调整的默认风格，不把你的三大 part 或论文名字硬编码成所有人的规则。
- **讲稿：** [spoken-notes.md](spoken-notes.md)。先告诉观众在看什么，再讲结论；过渡承接上一页；用口语；notes 只留可以说出来的话，也记录了 Keynote 深色 notes 区原生黑字自动适配的问题。
- **动画：** [motion.md](motion.md)。代码定义时间线和对象状态，再逐帧渲染；同时记录如何让多个变化同步，以及视频自动播放和 slide 自动跳页的区别。
- **迭代经验：** [lessons-learned.md](lessons-learned.md)。60 组具体经验，每组都有问题、修改方向和检查方法。以后新 agent 可以按问题查，不用一次读完。
- **保留手工修改：** [review-adaptation.md](review-adaptation.md)。先看最新保存版本，按内容 ID 定位，避免 slide 号码变化后改错页，也避免覆盖你的手动调整。

CLI 负责重复执行文件检查、预览、渲染和组装。论文理解、科学论点、讲述顺序仍由 agent 根据素材完成；不会因为跑了一个命令就自动得到经过验证的研究报告。

最后 review 不只看截图：还要看实际视频播放、Keynote 的自动播放/手动翻页、notes 显示，以及与口述是否同步。公共发布和素材授权是另外一步，这次整理本身不代表已选择开源 license 或已允许发布私人素材。
