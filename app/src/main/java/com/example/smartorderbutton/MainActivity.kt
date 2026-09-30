package com.example.smartorderbutton

import android.animation.Animator
import android.content.Intent
import android.os.Bundle
import android.widget.LinearLayout
import android.widget.TextView
import androidx.appcompat.app.AppCompatActivity
import com.airbnb.lottie.LottieAnimationView

class MainActivity : AppCompatActivity() {
    override fun onCreate(savedInstanceState: Bundle?) {
        super.onCreate(savedInstanceState)
        setContentView(R.layout.activity_main)

        // Ánh xạ các thành phần giao diện (đã cập nhật LinearLayout cho Title)
        val lottieAnimation = findViewById<LottieAnimationView>(R.id.lottie_scooter)
        val llTitle = findViewById<LinearLayout>(R.id.ll_splash_title)
        val tvDesc = findViewById<TextView>(R.id.tv_splash_desc)

        var isTextShown = false

        // 1. Lắng nghe tiến trình chạy của xe để hiện chữ
        lottieAnimation.addAnimatorUpdateListener {
            // Khi xe chạy được 50% thời gian (0.5f) và chữ chưa được hiện
            if (lottieAnimation.progress >= 0.5f && !isTextShown) {
                isTextShown = true
                // Kích hoạt hiệu ứng làm rõ dần khối chữ trong vòng 0.8 giây (800ms)
                llTitle.animate().alpha(1f).setDuration(800).start()
                tvDesc.animate().alpha(1f).setDuration(800).start()
            }
        }

        // 2. Lắng nghe khi xe chạy xong hoàn toàn để lướt sang trang Login
        lottieAnimation.addAnimatorListener(object : Animator.AnimatorListener {
            override fun onAnimationStart(animation: Animator) {}
            override fun onAnimationCancel(animation: Animator) {}
            override fun onAnimationRepeat(animation: Animator) {}

            override fun onAnimationEnd(animation: Animator) {
                val intent = Intent(this@MainActivity, LoginActivity::class.java)
                startActivity(intent)

                // Hiệu ứng mờ dần mượt mà sang màn hình đăng nhập
                overridePendingTransition(android.R.anim.fade_in, android.R.anim.fade_out)
                finish()
            }
        })
    }
}