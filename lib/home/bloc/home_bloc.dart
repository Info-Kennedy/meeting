import 'dart:convert';

import 'package:chime/common/common.dart';
import 'package:chime/home/models/menu_item.dart';
import 'package:chime/home/repository/home_repository.dart';
import 'package:bloc/bloc.dart';
import 'package:equatable/equatable.dart';
import 'package:flutter/material.dart';
import 'package:logger/logger.dart';

part 'home_event.dart';
part 'home_state.dart';

class HomeBloc extends Bloc<HomeEvent, HomeState> {
  final log = Logger();
  final HomeRepository _repository;

  HomeBloc({required HomeRepository repository}) : _repository = repository, super(HomeState.initial) {
    on<InitializeHomePage>(_onInitializeHomePageToState);
    on<UpdateBottomNavItem>(_onUpdateBottomNavItemToState);
    on<BottomNavView>(_onBottomNavViewToState);
  }

  Future<void> _onInitializeHomePageToState(InitializeHomePage event, Emitter<HomeState> emit) async {
    CommonHelper commonHelper = CommonHelper();
    try {
      log.d("HomeBloc:::_onInitializeHomePageToState::event: $event");
      emit(state.copyWith(status: () => HomeStatus.initial));
      List<MenuItem> bottomMenuItems = await _repository.getBottomNavigationConfig();

      String? menuItem = await _repository.prefRepo.getPreference(Constants.PREF_KEY_MENU_ITEM);
      MenuItem selectedMenuItem = bottomMenuItems.first;
      if (menuItem != null) {
        selectedMenuItem = MenuItem.fromJson(jsonDecode(menuItem));
        if (selectedMenuItem.id == "") {
          selectedMenuItem = bottomMenuItems.first;
        }
      }
      emit(state.copyWith(status: () => HomeStatus.loaded, bottomMenuItems: () => bottomMenuItems, selectedBottomMenuItem: () => selectedMenuItem));
    } catch (error) {
      log.e("HomeBloc::Error in _onInitializeHomePageToState: $error");
      emit(state.copyWith(status: () => HomeStatus.error, message: () => commonHelper.getStringLabelSync("access_revoked")));
    }
  }

  Future<void> _onUpdateBottomNavItemToState(UpdateBottomNavItem event, Emitter<HomeState> emit) async {
    try {
      emit(state.copyWith(status: () => HomeStatus.loading));
      log.d("HomeBloc:::_onUpdateNavItemToState::Event: ${event.menuItem.toJson()}");
      _repository.prefRepo.savePreference(Constants.PREF_KEY_MENU_ITEM, jsonEncode(event.menuItem.toJson()));
      emit(state.copyWith(status: () => HomeStatus.changed, selectedBottomMenuItem: () => event.menuItem));
    } catch (error) {
      log.e("HomeBloc:::_onUpdateNavItemToState::Error: $error");
    }
  }

  Future<void> _onBottomNavViewToState(BottomNavView event, Emitter<HomeState> emit) async {
    try {
      emit(state.copyWith(status: () => HomeStatus.changing));
      log.d("HomeBloc:::_onBottomNavViewToState::Event: ${event.view}");
      emit(state.copyWith(status: () => HomeStatus.changed, showBottomNav: () => event.view));
    } catch (error) {
      log.e("HomeBloc:::_onBottomNavViewToState::Error: $error");
    }
  }
}
