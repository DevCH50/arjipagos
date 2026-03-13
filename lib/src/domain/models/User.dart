class User {
    int id;
    String username;
    String email;
    String nombre;
    String apPaterno;
    String apMaterno;
    String curp;
    String emails;
    String celulares;
    String telefonos;
    dynamic fechaNacimiento;
    int genero;
    String uuid;
    int activo;
    String fullName;
    String fullNameWithUsername;
    String pathImageProfile;

    User({
        required this.id,
        required this.username,
        required this.email,
        required this.nombre,
        required this.apPaterno,
        required this.apMaterno,
        required this.curp,
        required this.emails,
        required this.celulares,
        required this.telefonos,
        required this.fechaNacimiento,
        required this.genero,
        required this.uuid,
        required this.activo,
        required this.fullName,
        required this.fullNameWithUsername,
        required this.pathImageProfile,
    });

    factory User.fromJson(Map<String, dynamic> json) => User(
        id: json['id'] ?? 0,
        username: json['username']?.toString() ?? '',
        email: json['email']?.toString() ?? '',
        nombre: json['nombre']?.toString() ?? '',
        apPaterno: json['ap_paterno']?.toString() ?? '',
        apMaterno: json['ap_materno']?.toString() ?? '',
        curp: json['curp']?.toString() ?? '',
        emails: json['emails']?.toString() ?? '',
        celulares: json['celulares']?.toString() ?? '',
        telefonos: json['telefonos']?.toString() ?? '',
        fechaNacimiento: json['fecha_nacimiento'],
        genero: json['genero'] ?? 0,
        uuid: json['uuid']?.toString() ?? '',
        activo: json['activo'] ?? 0,
        fullName: json['full_name']?.toString() ?? '',
        fullNameWithUsername: json['full_name_with_username']?.toString() ?? '',
        pathImageProfile: json['path_image_profile']?.toString() ?? '',
    );

    Map<String, dynamic> toJson() => {
        'id': id,
        'username': username,
        'email': email,
        'nombre': nombre,
        'ap_paterno': apPaterno,
        'ap_materno': apMaterno,
        'curp': curp,
        'emails': emails,
        'celulares': celulares,
        'telefonos': telefonos,
        'fecha_nacimiento': fechaNacimiento,
        'genero': genero,
        'uuid': uuid,
        'activo': activo,
        'full_name': fullName,
        'full_name_with_username': fullNameWithUsername,
        'path_image_profile': pathImageProfile,
    };
}
