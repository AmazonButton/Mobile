package com.example.smartorderbutton

import android.content.Intent
import android.os.Bundle
import android.text.method.HideReturnsTransformationMethod
import android.text.method.PasswordTransformationMethod
import android.util.Patterns
import android.view.View
import android.widget.EditText
import android.widget.ImageView
import android.widget.LinearLayout
import android.widget.TextView
import android.widget.Toast
import androidx.appcompat.app.AppCompatActivity
import com.google.android.material.button.MaterialButton

class LoginActivity : AppCompatActivity() {

    private var isPasswordVisible = false

    override fun onCreate(savedInstanceState: Bundle?) {
        super.onCreate(savedInstanceState)
        setContentView(R.layout.activity_login)

        val edtEmail = findViewById<EditText>(R.id.edt_email)
        val edtPassword = findViewById<EditText>(R.id.edt_password)
        val btnLogin = findViewById<MaterialButton>(R.id.btn_login)
        val ivPasswordToggle = findViewById<ImageView>(R.id.iv_password_toggle)

        val tvErrorEmail = findViewById<TextView>(R.id.tv_error_email)
        val tvErrorPassword = findViewById<TextView>(R.id.tv_error_password)

        // Ánh xạ nút Đăng ký
        val llSignUp = findViewById<LinearLayout>(R.id.ll_signup)

        // 1. Chuyển sang trang Đăng ký (Có hiệu ứng mượt)
        llSignUp.setOnClickListener {
            val intent = Intent(this, SignUpActivity::class.java)
            startActivity(intent)
            overridePendingTransition(android.R.anim.fade_in, android.R.anim.fade_out)
        }

        // 2. Chức năng Ẩn/Hiện mật khẩu
        ivPasswordToggle.setOnClickListener {
            isPasswordVisible = !isPasswordVisible
            if (isPasswordVisible) {
                edtPassword.transformationMethod = HideReturnsTransformationMethod.getInstance()
                ivPasswordToggle.alpha = 1.0f
            } else {
                edtPassword.transformationMethod = PasswordTransformationMethod.getInstance()
                ivPasswordToggle.alpha = 0.5f
            }
            edtPassword.setSelection(edtPassword.text.length)
        }

        // 3. Kiểm tra dữ liệu khi bấm Đăng nhập
        btnLogin.setOnClickListener {
            val emailOrPhone = edtEmail.text.toString()
            val password = edtPassword.text.toString()

            var isValid = true
            tvErrorEmail.visibility = View.GONE
            tvErrorPassword.visibility = View.GONE

            if (emailOrPhone.isEmpty()) {
                tvErrorEmail.text = "Vui lòng nhập Email hoặc Số điện thoại."
                tvErrorEmail.visibility = View.VISIBLE
                isValid = false
            } else {
                val isEmail = emailOrPhone.contains("@") && Patterns.EMAIL_ADDRESS.matcher(emailOrPhone).matches()
                val isPhone = emailOrPhone.matches(Regex("^[0-9]{10,11}$"))

                if (!isEmail && !isPhone) {
                    tvErrorEmail.text = "Sai định dạng! Nhập Email (vd: @gmail.com) hoặc SĐT (10-11 số, không khoảng trắng)."
                    tvErrorEmail.visibility = View.VISIBLE
                    isValid = false
                }
            }

            if (password.isEmpty()) {
                tvErrorPassword.text = "Vui lòng nhập mật khẩu."
                tvErrorPassword.visibility = View.VISIBLE
                isValid = false
            } else {
                val hasMinLength = password.length >= 8
                val hasUppercase = password.any { it.isUpperCase() }
                val hasSpecialChar = password.any { !it.isLetterOrDigit() }
                val hasNoSpaces = !password.contains(" ")
                val isAscii = password.all { it.code in 33..126 }

                if (!hasMinLength || !hasUppercase || !hasSpecialChar || !hasNoSpaces || !isAscii) {
                    tvErrorPassword.text = "Mật khẩu sai quy tắc! Yêu cầu:\n- Từ 8 ký tự trở lên\n- Có ít nhất 1 chữ viết hoa\n- Có ít nhất 1 ký tự đặc biệt (!, @, #...)\n- Không khoảng trắng, không dấu."
                    tvErrorPassword.visibility = View.VISIBLE
                    isValid = false
                }
            }

            if (isValid) {
                Toast.makeText(this, "Đăng nhập thành công!", Toast.LENGTH_SHORT).show()
            }
        }
    }
}