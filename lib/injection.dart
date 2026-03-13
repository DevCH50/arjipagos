import 'package:arjipagos/injection.config.dart';
import 'package:get_it/get_it.dart';
import 'package:injectable/injectable.dart';

final locator = GetIt.instance;

@InjectableInit()
Future<void> configureDependencies() async => locator.init();



// Nota

// Para generar el archivo de inyección en modo Developer 
//$ flutter packages pub run build_runner watch 

// Para generar el archivo de inyección en modo Production 
//$ flutter packages pub run build_runner build 

// Limpiar la cache de inyección
//$ flutter packages pub run build_runner clean

// Generar el archivo de inyección en modo Production
//$ flutter packages pub run build_runner build --delete-conflicting-outputs

