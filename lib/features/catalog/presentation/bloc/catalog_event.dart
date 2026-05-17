part of 'catalog_bloc.dart';

abstract class CatalogEvent extends Equatable {
  const CatalogEvent();

  @override
  List<Object?> get props => [];
}

class CatalogSearchRequested extends CatalogEvent {
  const CatalogSearchRequested({this.query, this.moodTag});

  final String? query;
  final String? moodTag;

  @override
  List<Object?> get props => [query, moodTag];
}

class CatalogCleared extends CatalogEvent {
  const CatalogCleared();
}
