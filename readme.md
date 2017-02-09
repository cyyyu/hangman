答[strikingly面试题](https://github.com/strikingly/strikingly-interview-test-instructions)，使用coffeescript。

该项目是个hangman游戏客户端，启动app.coffee文件则自动运行，服务端在strikingly（但貌似不太稳定）。

猜词因为词库问题借助了外部api，由google得来。

记：

  * 做‘选择可能性字母’时一开始做了去重处理，后来发现是多余的，不去重正好为可能性大的字母加权，随机选择到的可能性更大。

  * 没有达到目标分数的话程序不会停止，由于服务器不稳定，尚不清楚猜到80个仍然未结束游戏是什么情况，所以未做处理。

  * 目前尝试的最大分数仅有43（=_=），在猜词步骤上应该还有待优化，

