enum CommandIntent {
  add,
  complete,
  reschedule,
  delete,
  list,
  undo,
  confirmYes,
  confirmNo,
  selectOption,
  unknown;

  String get displayName {
    switch (this) {
      case CommandIntent.add:
        return 'ADD';
      case CommandIntent.complete:
        return 'COMPLETE';
      case CommandIntent.reschedule:
        return 'RESCHEDULE';
      case CommandIntent.delete:
        return 'DELETE';
      case CommandIntent.list:
        return 'LIST';
      case CommandIntent.undo:
        return 'UNDO';
      case CommandIntent.confirmYes:
        return 'CONFIRM_YES';
      case CommandIntent.confirmNo:
        return 'CONFIRM_NO';
      case CommandIntent.selectOption:
        return 'SELECT_OPTION';
      case CommandIntent.unknown:
        return 'UNKNOWN';
    }
  }
}

