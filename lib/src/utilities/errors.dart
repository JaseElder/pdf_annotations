sealed class TaskResult<T> {
  const TaskResult();
}

class Success<T> extends TaskResult<T> {
  final T data;
  const Success(this.data);
}

class Failure<T> extends TaskResult<T> {
  final String message;
  final dynamic error;
  final StackTrace? stackTrace;

  const Failure(this.message, {this.error, this.stackTrace});
}
