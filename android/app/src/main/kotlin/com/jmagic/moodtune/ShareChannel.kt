package com.jmagic.moodtune

import android.app.Activity
import android.content.Intent
import android.content.pm.PackageManager
import android.net.Uri
import androidx.core.content.FileProvider
import io.flutter.embedding.engine.FlutterEngine
import io.flutter.plugin.common.MethodCall
import io.flutter.plugin.common.MethodChannel
import java.io.File

/**
 * Native side of Dart's `moodtune/share` channel (issue #35, D2).
 *
 * Instagram Stories uses the documented `com.instagram.share.ADD_TO_STORY`
 * intent with the card as a sticker over a two-colour gradient (D3). X gets a
 * targeted `ACTION_SEND`. Files are copied into `cache/moodtune_share/` and
 * exposed through the `<applicationId>.moodtune.share` FileProvider.
 */
class ShareChannel(private val activity: Activity) {
    companion object {
        const val NAME = "moodtune/share"
        const val INSTAGRAM = "com.instagram.android"
        const val X = "com.twitter.android"
        const val CACHE_DIR = "moodtune_share"
    }

    fun register(engine: FlutterEngine) {
        MethodChannel(engine.dartExecutor.binaryMessenger, NAME).setMethodCallHandler { call, result ->
            try {
                when (call.method) {
                    "isInstagramInstalled" -> result.success(isInstalled(INSTAGRAM))
                    "isXInstalled" -> result.success(isInstalled(X))
                    "shareToInstagramStory" -> result.success(
                        shareToInstagramStory(
                            stickerPath = call.requireArg("stickerPath"),
                            topColor = call.requireArg("topColor"),
                            bottomColor = call.requireArg("bottomColor"),
                            appId = call.requireArg("appId"),
                        )
                    )
                    "shareImageToX" -> result.success(
                        shareImageToX(
                            imagePath = call.requireArg("imagePath"),
                            text = call.requireArg("text"),
                        )
                    )
                    else -> result.notImplemented()
                }
            } catch (e: IllegalArgumentException) {
                result.error("bad_args", e.message, null)
            } catch (e: Exception) {
                result.error("share_failed", e.message ?: e.javaClass.simpleName, null)
            }
        }
    }

    private fun MethodCall.requireArg(key: String): String =
        argument<String>(key) ?: throw IllegalArgumentException("Missing argument: $key")

    private fun isInstalled(packageName: String): Boolean = try {
        activity.packageManager.getPackageInfo(packageName, 0)
        true
    } catch (e: PackageManager.NameNotFoundException) {
        false
    }

    /** Copies [path] into the provider's cache folder and returns a content URI. */
    private fun contentUri(path: String): Uri {
        val source = File(path)
        require(source.isFile) { "No file at $path" }
        val dir = File(activity.cacheDir, CACHE_DIR).apply { mkdirs() }
        val copy = File(dir, source.name)
        if (source.canonicalPath != copy.canonicalPath) {
            source.copyTo(copy, overwrite = true)
        }
        return FileProvider.getUriForFile(activity, "${activity.packageName}.moodtune.share", copy)
    }

    private fun shareToInstagramStory(
        stickerPath: String,
        topColor: String,
        bottomColor: String,
        appId: String,
    ): Boolean {
        if (!isInstalled(INSTAGRAM)) return false
        val uri = contentUri(stickerPath)
        val intent = Intent("com.instagram.share.ADD_TO_STORY").apply {
            setPackage(INSTAGRAM)
            type = "image/png"
            putExtra("source_application", appId)
            putExtra("interactive_asset_uri", uri)
            putExtra("top_background_color", topColor)
            putExtra("bottom_background_color", bottomColor)
            addFlags(Intent.FLAG_GRANT_READ_URI_PERMISSION)
        }
        activity.grantUriPermission(INSTAGRAM, uri, Intent.FLAG_GRANT_READ_URI_PERMISSION)
        if (activity.packageManager.resolveActivity(intent, 0) == null) return false
        activity.startActivity(intent)
        return true
    }

    private fun shareImageToX(imagePath: String, text: String): Boolean {
        if (!isInstalled(X)) return false
        val uri = contentUri(imagePath)
        val intent = Intent(Intent.ACTION_SEND).apply {
            setPackage(X)
            type = "image/png"
            putExtra(Intent.EXTRA_TEXT, text)
            putExtra(Intent.EXTRA_STREAM, uri)
            addFlags(Intent.FLAG_GRANT_READ_URI_PERMISSION)
        }
        activity.grantUriPermission(X, uri, Intent.FLAG_GRANT_READ_URI_PERMISSION)
        if (activity.packageManager.resolveActivity(intent, 0) == null) return false
        activity.startActivity(intent)
        return true
    }
}
