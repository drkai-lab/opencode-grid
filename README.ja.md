# opencode4

**`SUPER + ]` を押すと、opencode が4ペインで立ち上がります。オーケストレーター1人とワーカー3人、小さなチームの出来上がりです。**

[English](README.md)

## これは何か

opencode を tmux の2x2グリッドで並べたものです。左上がオーケストレーター、仕事を振る側。残り3つがワーカーで、実際に作業する側です。連絡はディスク上のテキストログ経由。オーケストレーターはウィンドウを探し回らずに、全員の報告をまとめられます。

各ペインの右には Todo サイドバーがあって、そのエージェントが今やっているタスクが表示されます。`oc-todo-clear` で完了した分を消せるので、サイドバーには進行中のものだけが残ります。

Mac 時代の `cmd + ]` の癖が忘れられなくて、[Omarchy](https://omarchy.org/) でも使えるように作りました。中身は bash スクリプト数本とキーバインド1つだけ。tmux と opencode と Hyprland があれば動きます。

## 必要なもの

- Hyprland(omarchy に含まれます。最近のバージョンなら大丈夫)
- tmux と opencode
- ターミナル: ghostty / kitty / foot / alacritty / xdg-terminal-exec
- uwsm-app(Wayland セッション内でターミナルを開くために使います。なくてもインストーラが警告するだけ)
- opencode にモデルを渡す何か。ローカルの [Ollama](https://ollama.com/) でもクラウドでも OK

## インストール

かんたん版:

```bash
git clone https://github.com/drkai-lab/opencode4.git
cd opencode4
./install.sh
```

これで `opencode4`・`oc-send`・`oc-todo-view`・`oc-todo-clear` が `~/.local/bin` に入り、エージェント定義2つが `~/.config/opencode/agents/` にコピーされます(すでにあるファイルには触りません)。キーバインドが `~/.config/hypr/bindings.conf` に追加されて、Hyprland を再読み込みします。もう一度実行しても、あるものはスキップするだけです。

手動でやるなら:

```bash
install -m755 bin/opencode4 bin/oc-send bin/oc-todo-view bin/oc-todo-clear ~/.local/bin/
cp agents/orchestrator.md agents/worker.md ~/.config/opencode/agents/
```

`~/.config/hypr/bindings.conf` に1行足します:

```
bindd = SUPER, bracketright, OpenCode 4-pane, exec, uwsm-app -- ghostty -e ~/.local/bin/opencode4
```

## 使い方

1. `SUPER + ]` を押す。今いるディレクトリでグリッドが起動します。すでに動いていれば、そのセッションに戻るだけです。
2. 左上がオーケストレーター、残りがワーカーです。
3. オーケストレーターのペインから、ワーカーに指示を送れます:

   ```bash
   oc-send WORKER-1 "auth モジュールをリファクタリングして、結果を報告して"
   ```

4. ワーカーは `~/.local/state/oc-grid/wire.log` に返事を書きます。オーケストレーターがそれを読んで、まとめて返してくれます。
5. Todo サイドバーを見ると、各エージェントが今何をしているか分かります。完了報告が来れば、その Todo は自動で消えます。
6. 席を外すなら `Ctrl-b d` でデタッチ。セッションは裏で動き続けるので、`SUPER + ]` でいつでも戻れます。

グリッドを操るキーはあと2つあります:

- `SUPER + [` はターミナルウィンドウを閉じつつ、4つのエージェントをバックグラウンドで動かし続けます。セッションは生きているので、`SUPER + ]` で戻れます。
- `SUPER + W` は全部終了します。エージェントもターミナルウィンドウも閉じます。いつもの「ウィンドウを閉じる」を `SUPER + W` が上書きする点に注意。完全に閉じたいなら `SUPER ALT + W` が残っています。

グリッドの状態は全部 `~/.local/state/oc-grid/` に入っています(wire log、ロール→ペイン対応表、サイドバーが読む `todo/` ファイル)。このフォルダを消せば、まっさらからやり直せます。

## 調整

`~/.config/opencode/agents/` の定義がオーケストレーターとワーカーの役割を決めています。一度作ったファイルにはインストーラは触らないので、自由に編集してください。たいていは `model:` の行を自分のバックエンドに合わせるだけ。編集したらグリッドを再起動すれば OK です。

Todo サイドバーは `~/.local/state/oc-grid/todo/<ROLE>` の内容を表示します。`oc-send` が送信したタスクをここに書き込み、`oc-todo-clear <ROLE>` で消します(新しいタスクに差し替えもできます)。サイドバーの幅は環境変数 `OC_GRID_TODO_PCT` で、デフォルトは各ペインの23%です。

## 削除

```bash
./uninstall.sh
```

スクリプトとエージェント定義(手を入れたものは残します)とキーバインドを削除して、Hyprland を再読み込みします。

## ライセンス

MIT © drkai-lab
