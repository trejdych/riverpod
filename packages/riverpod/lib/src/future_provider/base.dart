part of '../future_provider.dart';

/// {@macro riverpod.providerrefbase}
/// - [state], the value currently exposed by this provider.
abstract class FutureProviderRef<State> implements Ref<AsyncValue<State>> {
  /// Obtains the state currently exposed by this provider.
  ///
  /// Mutating this property will notify the provider listeners.
  ///
  /// Cannot be called while a provider is creating, unless the setter was called first.
  ///
  /// Will return [AsyncLoading] if used during the first initialization.
  /// Subsequent initializations will contain an [AsyncValue] with the previous
  /// state and [AsyncValueX.isRefreshing]/[AsyncValueX.isReloading] set accordingly.
  AsyncValue<State> get state;
  set state(AsyncValue<State> newState);

  /// Obtains the [Future] associated to this provider.
  ///
  /// This is equivalent to doing `ref.read(myProvider.future)`.
  /// See also [FutureProvider.future].
  Future<State> get future;
}

/// {@macro riverpod.futureprovider}
class FutureProvider<T> extends _FutureProviderBase<T>
    with AlwaysAliveProviderBase<AsyncValue<T>>, AlwaysAliveAsyncSelector<T> {
  /// {@macro riverpod.futureprovider}
  FutureProvider(
    this._createFn, {
    super.name,
    super.from,
    super.argument,
    super.dependencies,
    super.debugGetCreateSourceHash,
  });

  /// {@macro riverpod.autoDispose}
  static const autoDispose = AutoDisposeFutureProviderBuilder();

  /// {@macro riverpod.family}
  static const family = FutureProviderFamilyBuilder();

  final Create<FutureOr<T>, FutureProviderRef<T>> _createFn;

  @override
  late final AlwaysAliveRefreshable<Future<T>> future = _future(this);

  @override
  FutureOr<T> _create(FutureProviderElement<T> ref) => _createFn(ref);

  @override
  FutureProviderElement<T> createElement() => FutureProviderElement._(this);

  /// {@macro riverpod.overridewith}
  Override overrideWith(Create<FutureOr<T>, FutureProviderRef<T>> create) {
    return ProviderOverride(
      origin: this,
      override: FutureProvider(
        create,
        from: from,
        argument: argument,
      ),
    );
  }
}

/// The element of a [FutureProvider]
class FutureProviderElement<T> extends ProviderElementBase<AsyncValue<T>>
    with FutureHandlerProviderElementMixin<T>
    implements FutureProviderRef<T> {
  FutureProviderElement._(_FutureProviderBase<T> super.provider);

  @override
  AsyncValue<T> get state => requireState;

  @override
  Future<T> get future {
    flush();
    return futureNotifier.value;
  }

  @override
  bool updateShouldNotify(AsyncValue<T> previous, AsyncValue<T> next) {
    return FutureHandlerProviderElementMixin.handleUpdateShouldNotify(
      previous,
      next,
    );
  }

  @override
  void create({required bool didChangeDependency}) {
    final provider = this.provider as _FutureProviderBase<T>;

    return handleFuture(
      () => provider._create(this),
      didChangeDependency: didChangeDependency,
    );
  }
}

/// The [Family] of a [FutureProvider]
class FutureProviderFamily<R, Arg> extends FamilyBase<FutureProviderRef<R>,
    AsyncValue<R>, Arg, FutureOr<R>, FutureProvider<R>> {
  /// The [Family] of a [FutureProvider]
  FutureProviderFamily(
    super.create, {
    super.name,
    super.dependencies,
  }) : super(providerFactory: FutureProvider<R>.new);

  /// {@macro riverpod.overridewith}
  Override overrideWith(
    FutureOr<R> Function(FutureProviderRef<R> ref, Arg arg) create,
  ) {
    return FamilyOverrideImpl<AsyncValue<R>, Arg, FutureProvider<R>>(
      this,
      (arg) => FutureProvider<R>(
        (ref) => create(ref, arg),
        from: from,
        argument: arg,
      ),
    );
  }
}
