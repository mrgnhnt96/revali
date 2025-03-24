enum WebsocketType {
  none,
  canSendOnly,
  canReceiveOnly,
  canSendAndReceive;

  const WebsocketType();

  bool get canSendMany {
    return switch (this) {
      WebsocketType.none || WebsocketType.canReceiveOnly => false,
      WebsocketType.canSendOnly || WebsocketType.canSendAndReceive => true,
    };
  }

  bool get canSendAny {
    return switch (this) {
      WebsocketType.none || WebsocketType.canReceiveOnly => false,
      WebsocketType.canSendOnly || WebsocketType.canSendAndReceive => true,
    };
  }

  bool get canReceive {
    return switch (this) {
      WebsocketType.none || WebsocketType.canSendOnly => false,
      WebsocketType.canReceiveOnly || WebsocketType.canSendAndReceive => true,
    };
  }
}
