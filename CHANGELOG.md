# 1.2.0
 - Added support for resolution aliases, allowing a plugin that uses `ecs_select` to support multiple ECS versions with a single declaration.

# 1.1.0
 - Added support for `ecs_select` helper, allowing plugins to declare mappings that are selected during plugin instantiation.

# 1.0.0
 - Support Mixin for ensuring a plugin has an `ecs_compatibility` method that is configurable from an `ecs_compatibility` option that accepts the literal `disabled` or a v-prefixed integer representing a major ECS version (e.g., `v1`), using the implementation from Logstash core if available.
