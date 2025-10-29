import 'package:bloc/bloc.dart';
import 'package:chime/common/common.dart';
import 'package:chime/login/models/login_model.dart';
import 'package:chime/login/models/user_model.dart';
import 'package:chime/login/repository/login_repository.dart';
import 'package:equatable/equatable.dart';
import 'package:flutter/material.dart';
import 'package:logger/logger.dart';

part 'login_event.dart';
part 'login_state.dart';

class LoginBloc extends Bloc<LoginEvent, LoginState> {
  final log = Logger();
  final LoginRepository _repository;

  LoginBloc({required LoginRepository repository}) : _repository = repository, super(LoginState.initial) {
    on<InitializeLogin>(_onInitializeLoginToState);
    on<ChangeFormValue>(_onChangeFormValueToState);
    on<LoginSubmit>(_onLoginSubmitToState);
    on<TogglePasswordVisibility>(_onTogglePasswordVisibilityToState);
    on<Logout>(_onLoginOutToState);
  }

  Future<void> _onInitializeLoginToState(InitializeLogin event, Emitter<LoginState> emit) async {
    log.d("LoginBloc:::_onInitializeLoginToState:Event:: $event");
    emit(state.copyWith(status: () => LoginStatus.initial));
    try {
      final response = await _repository.isUserLoggedIn();
      log.d("LoginBloc:::_onInitializeLoginToState:Response:: $response");
      if (response) {
        final userData = _repository.prefRepo.getPreference(Constants.PREF_KEY_USER) ?? UserModel.getInstance().toString();
        UserModel userModel = UserModel.fromJson(userData);
        emit(state.copyWith(status: () => LoginStatus.loggedIn, userLanguage: () => "en", userModel: () => userModel));
      } else {
        emit(state.copyWith(status: () => LoginStatus.loaded, userLanguage: () => "en"));
      }
    } catch (error) {
      log.e("LoginBloc::Error in _onInitializeLoginToState: $error");
      emit(state.copyWith(status: () => LoginStatus.error, message: () => ErrorHandler.handleException(error)));
    }
  }

  Future<void> _onChangeFormValueToState(ChangeFormValue event, Emitter<LoginState> emit) async {
    log.d("LoginBloc:::_onChangeFormValueToState:Event:: $event");
    emit(state.copyWith(status: () => LoginStatus.changing));
    try {
      emit(state.copyWith(status: () => LoginStatus.changed, formValue: () => LoginModel.fromMap(event.formValue)));
    } catch (error) {
      log.e("LoginBloc::Error in _onChangeFormValueToState: $error");
      emit(state.copyWith(status: () => LoginStatus.error, message: () => error.toString()));
    }
  }

  Future<void> _onLoginSubmitToState(LoginSubmit event, Emitter<LoginState> emit) async {
    log.d("LoginBloc:::_onLoginSubmitToState:Event:: $event");
    emit(state.copyWith(status: () => LoginStatus.loading));
    try {
      final formValue = state.formValue!.toMap();
      log.d("LoginBloc:::_onLoginSubmitToState:FormValue:: $formValue");
      final response = await _repository.login(formValue);
      if (response != null) {
        if (response['success'] == true) {
          emit(state.copyWith(status: () => LoginStatus.success, message: () => response['message']));
        } else {
          emit(state.copyWith(status: () => LoginStatus.error, message: () => response['message']));
        }
      }
    } catch (error) {
      log.e("LoginBloc::Error in _onLoginSubmitToState: $error");
      emit(state.copyWith(status: () => LoginStatus.error, message: () => ErrorHandler.handleException(error)));
    }
  }

  Future<void> _onTogglePasswordVisibilityToState(TogglePasswordVisibility event, Emitter<LoginState> emit) async {
    log.d("LoginBloc:::_onTogglePasswordVisibilityToState:Event:: $event");
    emit(state.copyWith(isObscure: () => !state.isObscure));
  }

  Future<void> _onLoginOutToState(Logout event, Emitter<LoginState> emit) async {
    log.d("LoginBloc:::_onLoginOutToState:Event:: $event");
    emit(state.copyWith(status: () => LoginStatus.loading));
    try {
      await _repository.prefRepo.removeAllPreference();
      emit(state.copyWith(status: () => LoginStatus.loggedOut));
    } catch (error) {
      log.e("LoginBloc::Error in _onLoginOutToState: $error");
      emit(state.copyWith(status: () => LoginStatus.error, message: () => error.toString().replaceAll("Exception:", "")));
    }
  }
}
