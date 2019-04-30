import 'package:flutter/foundation.dart';
import 'package:flutter/widgets.dart';

Type _typeOf<T>() => T;

typedef UpdateShouldNotify<T> = bool Function(T oldPackage, T newPackage);

/// Base class for providers
abstract class _ProviderBase implements Widget {
  /// Return this provider with a given child.
  _ProviderBase withChild(Widget child);
}

/// A generic implementation of [_ProviderBase]
class Provider<T> extends InheritedWidget implements _ProviderBase {
  final T package;
  final UpdateShouldNotify<T> _updateShouldNotify;

  const Provider({
    Key key,
    UpdateShouldNotify<T> updateShouldNotify,
    @required this.package,
    Widget child,
  })  : _updateShouldNotify = updateShouldNotify,
        super(key: key, child: child);

  /// Obtains the nearest [Provider] and returns its [T] package.
  static T of<T>(BuildContext context, {bool listenToChanges = true}) {
    final type = _typeOf<Provider<T>>();
    final provider = listenToChanges
        ? context.inheritFromWidgetOfExactType(type) as Provider<T>
        : context.ancestorInheritedElementForWidgetOfExactType(type)?.widget
    as Provider<T>;

    if (provider == null) {
      throw NoSuchProviderError(T, context.widget.runtimeType);
    }

    return provider.package;
  }

  @override
  bool updateShouldNotify(Provider<T> oldWidget) {
    if (_updateShouldNotify != null) {
      return _updateShouldNotify(oldWidget.package, package);
    }
    return oldWidget.package != package;
  }

  /// Returns same [Provider] with a new child.
  @override
  Provider<T> withChild(Widget child) {
    return Provider<T>(
      key: key,
      package: package,
      updateShouldNotify: _updateShouldNotify,
      child: child,
    );
  }
}

/// A provider that can dispose its package
class DisposableProvider<T> extends StatefulWidget implements _ProviderBase {
  /// A function that builds a package
  ///
  /// [packageBuilder] cannot be null and is invoked only once for the life-cycle of [DisposableProvider].
  final T Function(BuildContext context) packageBuilder;

  /// [onDispose] will be called when [DisposableProvider]
  /// is being removed from the Widget tree.
  final void Function(BuildContext context, T value) onDispose;

  /// Overrides updateShouldNotify method of [Provider].
  final UpdateShouldNotify<T> updateShouldNotify;

  final Widget child;

  DisposableProvider({
    this.child,
    this.onDispose,
    this.updateShouldNotify,
    @required this.packageBuilder,
    Key key,
  })  : assert(packageBuilder != null),
        super(key: key);

  @override
  _DisposableProviderState<T> createState() => _DisposableProviderState<T>();

  /// Returns same [DisposableProvider] with a new child.
  @override
  DisposableProvider<T> withChild(Widget child) {
    return DisposableProvider<T>(
      key: key,
      packageBuilder: packageBuilder,
      updateShouldNotify: updateShouldNotify,
      onDispose: onDispose,
      child: child,
    );
  }
}

/// State of [DisposableProvider]
class _DisposableProviderState<T> extends State<DisposableProvider<T>> {
  T _package;

  @override
  void initState() {
    super.initState();
    _package = widget.packageBuilder(context);
  }

  @override
  void dispose() {
    if (widget.onDispose != null) {
      widget.onDispose(context, _package);
    }
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    return Provider(
      package: _package,
      updateShouldNotify: widget.updateShouldNotify,
      child: widget.child,
    );
  }
}

/// A provider that can absorb other providers
class MultiProvider extends StatelessWidget implements _ProviderBase {
  final List<_ProviderBase> providers;
  final Widget child;

  const MultiProvider({
    Key key,
    @required this.providers,
    this.child,
  })  : assert(providers != null),
        super(key: key);

  @override
  Widget build(BuildContext context) {
    var treeOfProviders = child;
    for (final provider in providers.reversed) {
      treeOfProviders = provider.withChild(treeOfProviders);
    }
    return treeOfProviders;
  }

  @override
  MultiProvider withChild(Widget child) {
    return MultiProvider(
      key: key,
      providers: providers,
      child: child,
    );
  }
}

/// Error that that means provider couldn't be found
class NoSuchProviderError extends Error {
  /// Type of the package that needs to be provided
  final Type packageType;

  /// Type of the Widget trying to find provider
  final Type widgetType;

  NoSuchProviderError(
      this.packageType,
      this.widgetType,
      );

  @override
  String toString() {
    return 'Error: Could not find a Provider<$packageType> above $widgetType Widget.';
  }
}
