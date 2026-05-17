import 'package:equatable/equatable.dart';
import 'package:flutter_bloc/flutter_bloc.dart';
import 'package:moodtune_app/features/catalog/domain/entities/jamendo_track.dart';
import 'package:moodtune_app/features/catalog/domain/usecases/search_catalog.dart';
import 'package:rxdart/rxdart.dart';

part 'catalog_event.dart';
part 'catalog_state.dart';

EventTransformer<E> _debounceSwitch<E>(Duration duration) =>
    (events, mapper) => events.debounceTime(duration).switchMap(mapper);

class CatalogBloc extends Bloc<CatalogEvent, CatalogState> {
  CatalogBloc({required SearchCatalog searchCatalog})
    : _searchCatalog = searchCatalog,
      super(const CatalogInitial()) {
    on<CatalogSearchRequested>(
      _onSearchRequested,
      transformer: _debounceSwitch(const Duration(milliseconds: 300)),
    );
    on<CatalogCleared>(_onCleared);
  }

  final SearchCatalog _searchCatalog;

  Future<void> _onSearchRequested(
    CatalogSearchRequested event,
    Emitter<CatalogState> emit,
  ) async {
    // Nothing to search
    if ((event.query == null || event.query!.isEmpty) &&
        (event.moodTag == null || event.moodTag!.isEmpty)) {
      emit(const CatalogInitial());
      return;
    }

    emit(const CatalogLoading());

    final result = await _searchCatalog(
      query: event.query,
      moodTag: event.moodTag,
    );

    result.fold(
      (failure) => emit(CatalogError(failure.message)),
      (tracks) => emit(CatalogLoaded(tracks)),
    );
  }

  void _onCleared(CatalogCleared event, Emitter<CatalogState> emit) {
    emit(const CatalogInitial());
  }
}
