import 'package:flutter_riverpod/flutter_riverpod.dart';

import 'export_service_base.dart';
import 'export_service_stub.dart'
    if (dart.library.html) 'export_service_web.dart'
    if (dart.library.io) 'export_service_io.dart' as impl;

export 'export_service_base.dart';

ExportService createExportService() => impl.createExportService();

final exportServiceProvider = Provider<ExportService>(
  (ref) => createExportService(),
);
