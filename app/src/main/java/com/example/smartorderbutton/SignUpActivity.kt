package com.example.smartorderbutton

import android.graphics.Color
import android.os.Bundle
import android.text.method.HideReturnsTransformationMethod
import android.text.method.PasswordTransformationMethod
import android.view.View
import android.widget.CheckBox
import android.widget.EditText
import android.widget.ImageView
import android.widget.LinearLayout
import android.widget.TextView
import android.widget.Toast
import androidx.appcompat.app.AppCompatActivity
import com.google.android.material.button.MaterialButton
import com.google.android.material.card.MaterialCardView

class SignUpActivity : AppCompatActivity() {

    private var currentStep = 1
    private var selectedRole = "Cư dân"
    private var isPasswordVisible = false
    private var isConfirmPasswordVisible = false

    override fun onCreate(savedInstanceState: Bundle?) {
        super.onCreate(savedInstanceState)
        setContentView(R.layout.activity_sign_up)

        // Step 1 Views
        val layoutStep1 = findViewById<LinearLayout>(R.id.layout_step_1)
        val cvResident = findViewById<MaterialCardView>(R.id.cv_role_resident)
        val cvShop = findViewById<MaterialCardView>(R.id.cv_role_shop)
        val cvDelivery = findViewById<MaterialCardView>(R.id.cv_role_delivery)
        val edtName = findViewById<EditText>(R.id.edt_name_signup)
        val edtPhone = findViewById<EditText>(R.id.edt_phone_signup)
        val edtEmail = findViewById<EditText>(R.id.edt_email_signup)
        val btnNext = findViewById<MaterialButton>(R.id.btn_next_step)
        val llBackToLogin = findViewById<LinearLayout>(R.id.ll_back_to_login)

        // Step 2 Views
        val layoutStep2 = findViewById<LinearLayout>(R.id.layout_step_2)
        val tvSummaryName = findViewById<TextView>(R.id.tv_summary_name)
        val tvSummaryInfo = findViewById<TextView>(R.id.tv_summary_info)
        val ivSummaryIcon = findViewById<ImageView>(R.id.iv_summary_role_icon)
        val btnEditInfo = findViewById<TextView>(R.id.btn_edit_info)
        val edtPassword = findViewById<EditText>(R.id.edt_password_signup)
        val edtConfirm = findViewById<EditText>(R.id.edt_confirm_password)
        val edtRoom = findViewById<EditText>(R.id.edt_room_number)
        val cbTerms = findViewById<CheckBox>(R.id.cb_terms)
        val btnSubmit = findViewById<MaterialButton>(R.id.btn_signup_submit)

        // Toggles password visibility (khớp ID với XML mới)
        val ivPasswordToggle = findViewById<ImageView>(R.id.iv_password_toggle)
        val ivConfirmToggle = findViewById<ImageView>(R.id.iv_confirm_password_toggle)

        // Header Views
        val btnBackHeader = findViewById<LinearLayout>(R.id.btn_back)
        val tvBackLabel = findViewById<TextView>(R.id.tv_back_label)
        val tvStepSubtitle = findViewById<TextView>(R.id.tv_step_subtitle)
        val viewStep1Ind = findViewById<View>(R.id.view_step1_indicator)
        val viewStep2Ind = findViewById<View>(R.id.view_step2_indicator)
        val tvStepCounter = findViewById<TextView>(R.id.tv_step_counter)

        // Xử lý chọn vai trò
        fun updateRoleUI(selected: MaterialCardView, roleName: String) {
            selectedRole = roleName
            val roles = listOf(cvResident, cvShop, cvDelivery)
            roles.forEach {
                if (it == selected) {
                    it.setStrokeColor(Color.parseColor("#F26C22"))
                    it.setCardBackgroundColor(Color.parseColor("#FFF5F0"))
                    // Đổi màu tint cho icon trong card nếu cần
                } else {
                    it.setStrokeColor(Color.parseColor("#EEEEEE"))
                    it.setCardBackgroundColor(Color.parseColor("#FFFFFF"))
                }
            }
        }

        cvResident.setOnClickListener { updateRoleUI(cvResident, "Cư dân") }
        cvShop.setOnClickListener { updateRoleUI(cvShop, "Cửa hàng") }
        cvDelivery.setOnClickListener { updateRoleUI(cvDelivery, "Giao hàng") }

        // Mật khẩu ẩn hiện
        ivPasswordToggle.setOnClickListener {
            isPasswordVisible = !isPasswordVisible
            edtPassword.transformationMethod = if (isPasswordVisible) 
                HideReturnsTransformationMethod.getInstance() else PasswordTransformationMethod.getInstance()
            ivPasswordToggle.alpha = if (isPasswordVisible) 1.0f else 0.5f
            edtPassword.setSelection(edtPassword.text.length)
        }

        ivConfirmToggle.setOnClickListener {
            isConfirmPasswordVisible = !isConfirmPasswordVisible
            edtConfirm.transformationMethod = if (isConfirmPasswordVisible) 
                HideReturnsTransformationMethod.getInstance() else PasswordTransformationMethod.getInstance()
            ivConfirmToggle.alpha = if (isConfirmPasswordVisible) 1.0f else 0.5f
            edtConfirm.setSelection(edtConfirm.text.length)
        }

        // Chuyển sang Bước 2
        btnNext.setOnClickListener {
            if (validateStep1(edtName, edtPhone, edtEmail)) {
                currentStep = 2
                layoutStep1.visibility = View.GONE
                layoutStep2.visibility = View.VISIBLE
                
                // Cập nhật Header
                tvStepSubtitle.text = "Bảo mật & căn hộ"
                tvStepCounter.text = "Bước 2/2"
                tvBackLabel.text = "Quay lại"
                viewStep1Ind.setBackgroundColor(Color.parseColor("#CCCCCC"))
                viewStep2Ind.setBackgroundColor(Color.parseColor("#F26C22"))
                
                // Cập nhật Summary
                tvSummaryName.text = edtName.text.toString()
                tvSummaryInfo.text = "$selectedRole - ${edtPhone.text}"
                
                // Đổi icon summary theo vai trò
                when(selectedRole) {
                    "Cư dân" -> ivSummaryIcon.setImageResource(android.R.drawable.ic_menu_myplaces)
                    "Cửa hàng" -> ivSummaryIcon.setImageResource(android.R.drawable.ic_menu_manage)
                    "Giao hàng" -> ivSummaryIcon.setImageResource(android.R.drawable.ic_menu_send)
                }
            }
        }

        // Quay lại Bước 1
        fun backToStep1() {
            currentStep = 1
            layoutStep1.visibility = View.VISIBLE
            layoutStep2.visibility = View.GONE
            tvStepSubtitle.text = "Thông tin cơ bản"
            tvStepCounter.text = "Bước 1/2"
            tvBackLabel.text = "Đăng nhập"
            viewStep1Ind.setBackgroundColor(Color.parseColor("#F26C22"))
            viewStep2Ind.setBackgroundColor(Color.parseColor("#CCCCCC"))
        }

        btnEditInfo.setOnClickListener { backToStep1() }
        btnBackHeader.setOnClickListener { if (currentStep == 2) backToStep1() else finish() }
        llBackToLogin.setOnClickListener { finish() }

        // Hoàn tất
        btnSubmit.setOnClickListener {
            if (validateStep2(edtPassword, edtConfirm, edtRoom, cbTerms)) {
                Toast.makeText(this, "Tạo tài khoản thành công!", Toast.LENGTH_SHORT).show()
                finish()
            }
        }
    }

    private fun validateStep1(name: EditText, phone: EditText, email: EditText): Boolean {
        if (name.text.trim().isEmpty()) {
            name.error = "Vui lòng nhập họ tên"
            return false
        }
        if (phone.text.length < 10) {
            phone.error = "Số điện thoại không hợp lệ"
            return false
        }
        return true
    }

    private fun validateStep2(pass: EditText, confirm: EditText, room: EditText, terms: CheckBox): Boolean {
        if (pass.text.length < 8) {
            pass.error = "Mật khẩu tối thiểu 8 ký tự"
            return false
        }
        if (pass.text.toString() != confirm.text.toString()) {
            confirm.error = "Mật khẩu không khớp"
            return false
        }
        if (room.text.isEmpty()) {
            room.error = "Vui lòng nhập số phòng"
            return false
        }
        if (!terms.isChecked) {
            Toast.makeText(this, "Bạn chưa đồng ý với điều khoản", Toast.LENGTH_SHORT).show()
            return false
        }
        return true
    }
}