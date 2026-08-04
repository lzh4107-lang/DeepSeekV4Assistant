import 'dart:async';

enum ChatAction {
  newTopic,
  toggleLeftPanelAssistants,
  toggleLeftPanelTopics,
  focusInput,
  switchModel,
  enterGlobalSearch,
  exitGlobalSearch,
}

class ChatActionBus {
  ChatActionBus._();
  static final ChatActionBus instance = ChatActionBus._();

  final _controller = StreamController<ChatAction>.broadcast();
  Stream<ChatAction> get stream => _controller.stream;
  void fire(ChatAction action) => _controller.add(action);
  void dispose() => _controller.close();
}

class ChatTextInsertBus {
  ChatTextInsertBus._();
  static final ChatTextInsertBus instance = ChatTextInsertBus._();

  final _controller = StreamController<String>.broadcast();
  Stream<String> get stream => _controller.stream;
  void fire(String text) => _controller.add(text);
  void dispose() => _controller.close();
}
