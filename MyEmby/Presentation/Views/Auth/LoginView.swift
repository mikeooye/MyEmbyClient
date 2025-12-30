//
//  LoginView.swift
//  MyEmby
//
//  Created by Claude on 2025/12/29.
//

import SwiftUI

/// 登录视图
struct LoginView: View {
    // 使用父视图传递的 ViewModel（如果没有则创建新实例）
    @State private var viewModel: AuthViewModel

    init(viewModel: AuthViewModel = AuthViewModel()) {
        _viewModel = State(initialValue: viewModel)
    }

    var body: some View {
        NavigationStack {
            ZStack {
                // 背景渐变
                LinearGradient(
                    gradient: Gradient(colors: [
                        Color.blue.opacity(0.3),
                        Color.purple.opacity(0.3)
                    ]),
                    startPoint: .topLeading,
                    endPoint: .bottomTrailing
                )
                .ignoresSafeArea()

                // 登录表单
                VStack(spacing: 24) {
                    Spacer()

                    // Logo 和标题
                    VStack(spacing: 12) {
                        Image(systemName: "play.rectangle.fill")
                            .font(.system(size: 80))
                            .foregroundStyle(.white)

                        Text("MyEmby")
                            .font(.largeTitle)
                            .fontWeight(.bold)
                            .foregroundStyle(.white)

                        Text("连接到您的媒体服务器")
                            .font(.subheadline)
                            .foregroundStyle(.white.opacity(0.8))
                    }
                    .padding(.bottom, 20)

                    // 表单
                    VStack(spacing: 16) {
                        // 服务器地址
                        VStack(alignment: .leading, spacing: 8) {
                            Text("服务器地址")
                                .font(.headline)
                                .foregroundStyle(.white)

                            TextField("例如: 192.168.1.100", text: $viewModel.loginForm.serverURL)
                                .textFieldStyle(.plain)
                                .padding()
                                .background(.ultraThinMaterial, in: RoundedRectangle(cornerRadius: 12))
                                .autocapitalization(.none)
                                .keyboardType(.URL)
                        }

                        // 端口和 HTTPS
                        HStack(spacing: 12) {
                            VStack(alignment: .leading, spacing: 8) {
                                Text("端口")
                                    .font(.headline)
                                    .foregroundStyle(.white)

                                TextField("端口", value: $viewModel.loginForm.port, format: .number)
                                    .textFieldStyle(.plain)
                                    .padding()
                                    .background(.ultraThinMaterial, in: RoundedRectangle(cornerRadius: 12))
                                    .keyboardType(.numberPad)
                            }

                            VStack(alignment: .leading, spacing: 8) {
                                Text("HTTPS")
                                    .font(.headline)
                                    .foregroundStyle(.white)

                                Toggle("", isOn: $viewModel.loginForm.useHTTPS)
                                    .labelsHidden()
                                    .padding()
                                    .background(.ultraThinMaterial, in: RoundedRectangle(cornerRadius: 12))
                            }
                        }

                        // 用户名
                        VStack(alignment: .leading, spacing: 8) {
                            Text("用户名")
                                .font(.headline)
                                .foregroundStyle(.white)

                            TextField("输入用户名", text: $viewModel.loginForm.username)
                                .textFieldStyle(.plain)
                                .padding()
                                .background(.ultraThinMaterial, in: RoundedRectangle(cornerRadius: 12))
                                .autocapitalization(.none)
                        }

                        // 密码
                        VStack(alignment: .leading, spacing: 8) {
                            Text("密码")
                                .font(.headline)
                                .foregroundStyle(.white)

                            SecureField("输入密码", text: $viewModel.loginForm.password)
                                .textFieldStyle(.plain)
                                .padding()
                                .background(.ultraThinMaterial, in: RoundedRectangle(cornerRadius: 12))
                        }
                    }
                    .padding(.horizontal)

                    // 错误提示
                    if let errorMessage = viewModel.errorMessage {
                        HStack(spacing: 8) {
                            Image(systemName: "exclamationmark.circle.fill")
                                .foregroundStyle(.red)

                            Text(errorMessage)
                                .font(.caption)
                                .foregroundStyle(.red)
                        }
                        .padding()
                        .background(.red.opacity(0.1), in: RoundedRectangle(cornerRadius: 8))
                        .padding(.horizontal)
                    }

                    // 登录按钮
                    Button(action: {
                        Task {
                            await viewModel.login()
                        }
                    }) {
                        HStack {
                            if viewModel.isLoading {
                                ProgressView()
                                    .progressViewStyle(CircularProgressViewStyle(tint: .white))
                                    .padding(.trailing, 8)
                            }

                            Text(viewModel.isLoading ? "登录中..." : "登录")
                                .font(.headline)
                                .frame(maxWidth: .infinity)
                        }
                        .padding()
                        .background(
                            viewModel.loginForm.isValid && !viewModel.isLoading
                                ? AnyShapeStyle(Color.blue)
                                : AnyShapeStyle(Color.gray)
                        )
                        .foregroundStyle(.white)
                        .cornerRadius(12)
                    }
                    .disabled(!viewModel.loginForm.isValid || viewModel.isLoading)
                    .padding(.horizontal)

                    Spacer()
                }
                .padding()
            }
            .navigationBarHidden(true)
        }
    }
}

// MARK: - 预览

#Preview {
    LoginView()
}
