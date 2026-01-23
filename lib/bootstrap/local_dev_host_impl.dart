import 'package:taskly_bloc/bootstrap/local_dev_host_stub.dart'
    if (dart.library.io) 'package:taskly_bloc/bootstrap/local_dev_host_io.dart';

String localDevHostImpl() => localDevHostImplInternal();
