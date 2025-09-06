/// New: strongly typed Reason model
class Reason {
  final String code;
  final String param;
  final String? message;

  const Reason({
    required this.code,
    required this.param,
    this.message,
  });

  factory Reason.fromJson(Map<String, dynamic> json) => Reason(
        code: (json["code"] as String?) ?? "",
        param: (json["param"] as String?) ?? "",
        message: json["message"] as String?, // backend-provided human text
      );

  Map<String, dynamic> toJson() => {
        "code": code,
        "param": param,
        if (message != null) "message": message,
      };
}