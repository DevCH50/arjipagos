import 'package:equatable/equatable.dart';

/// Entidad de dominio que representa una notificación del sistema.
///
/// Modela los datos de una notificación recibida desde el backend,
/// incluyendo información de lectura, contenido HTML y metadatos.
class Notificacion extends Equatable {
  /// Identificador único de la notificación.
  final int id;

  /// Identificador del usuario al que pertenece la notificación.
  final int userId;

  /// Título de la notificación.
  final String titulo;

  /// Cuerpo del mensaje. Puede contener HTML.
  final String mensaje;

  /// Tipo o campaña asociada a la notificación.
  final String campania;

  /// Fecha y hora de creación de la notificación.
  final DateTime fecha;

  /// Indica si la notificación ya fue leída por el usuario.
  final bool isRead;

  /// Etiquetas opcionales asociadas a la notificación.
  final String? tags;

  /// Constructor principal. Todos los campos son requeridos excepto [tags].
  const Notificacion({
    required this.id,
    required this.userId,
    required this.titulo,
    required this.mensaje,
    required this.campania,
    required this.fecha,
    required this.isRead,
    this.tags,
  });

  /// Crea una instancia de [Notificacion] a partir de un mapa JSON del backend.
  ///
  /// Campos del backend: "title", "message", "is_read" (bool), sin "user_id".
  factory Notificacion.fromJson(Map<String, dynamic> json) => Notificacion(
        id: json['id'] as int,
        userId: json['user_id'] as int? ?? 0,
        titulo: json['title'] as String? ?? '',
        mensaje: json['message'] as String? ?? '',
        campania: json['campania'] as String? ?? '',
        fecha: DateTime.parse(
          (json['fecha'] ?? json['created_at'] ?? '').toString(),
        ),
        isRead: json['is_read'] is bool
            ? json['is_read'] as bool
            : (json['is_read'] as int? ?? 0) == 1,
        tags: json['tags'] as String?,
      );

  /// Convierte la entidad a un mapa JSON compatible con el backend.
  Map<String, dynamic> toJson() => {
        'id': id,
        'user_id': userId,
        'titulo': titulo,
        'mensaje': mensaje,
        'campania': campania,
        'fecha': fecha.toIso8601String(),
        'is_read': isRead ? 1 : 0,
        'tags': tags,
      };

  /// Retorna una copia de la notificación con los campos especificados reemplazados.
  Notificacion copyWith({
    int? id,
    int? userId,
    String? titulo,
    String? mensaje,
    String? campania,
    DateTime? fecha,
    bool? isRead,
    String? tags,
  }) =>
      Notificacion(
        id: id ?? this.id,
        userId: userId ?? this.userId,
        titulo: titulo ?? this.titulo,
        mensaje: mensaje ?? this.mensaje,
        campania: campania ?? this.campania,
        fecha: fecha ?? this.fecha,
        isRead: isRead ?? this.isRead,
        tags: tags ?? this.tags,
      );

  @override
  List<Object?> get props => [
        id,
        userId,
        titulo,
        mensaje,
        campania,
        fecha,
        isRead,
        tags,
      ];
}
