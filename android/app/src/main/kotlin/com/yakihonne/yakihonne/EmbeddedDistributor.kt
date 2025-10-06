package com.yakihonne.yakihonne
import android.content.Context
import org.unifiedpush.android.foss_embedded_fcm_distributor.EmbeddedDistributorReceiver
class EmbeddedDistributor: EmbeddedDistributorReceiver() {
    override val googleProjectNumber = "434202752010"

    override fun getEndpoint(context: Context, token: String, instance: String): String {
        return "Embedded-FCM/FCM?v2&instance=$instance&token=$token"
    }
}