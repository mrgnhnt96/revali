import 'package:generic_lifecycle_fixture/components/rate_limit.dart';
import 'package:generic_lifecycle_fixture/models/bodies.dart';
import 'package:revali_router/revali_router.dart';

@RateLimit<UserBody>(maxRequests: 10)
@Post('')
void createUser() {}

@Get('')
@LifecycleComponents([RateLimit<OrderBody>])
void createOrder() {}

@LifecycleComponents([RateLimit])
@Get('generic')
void genericRateLimit() {}
