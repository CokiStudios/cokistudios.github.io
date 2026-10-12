package com.cokistudios.launcher.adapter

import android.view.LayoutInflater
import android.view.View
import android.view.ViewGroup
import android.widget.ImageView
import android.widget.TextView
import androidx.recyclerview.widget.RecyclerView
import com.cokistudios.launcher.R
import com.cokistudios.launcher.model.AppInfo

class AppGridAdapter(
    private var apps: List<AppInfo> = emptyList(),
    private val onAppClick: (AppInfo) -> Unit,
    private val onAppLongClick: ((AppInfo) -> Boolean)? = null
) : RecyclerView.Adapter<AppGridAdapter.AppViewHolder>() {

    class AppViewHolder(itemView: View) : RecyclerView.ViewHolder(itemView) {
        val ivIcon: ImageView = itemView.findViewById(R.id.appIcon)
        val tvLabel: TextView = itemView.findViewById(R.id.appLabel)
    }

    override fun onCreateViewHolder(parent: ViewGroup, viewType: Int): AppViewHolder {
        val view = LayoutInflater.from(parent.context).inflate(R.layout.item_app_grid, parent, false)
        return AppViewHolder(view)
    }

    override fun onBindViewHolder(holder: AppViewHolder, position: Int) {
        val app = apps[position]
        holder.tvLabel.text = app.label
        holder.ivIcon.setImageDrawable(app.icon)

        holder.itemView.setOnClickListener {
            onAppClick(app)
        }

        holder.itemView.setOnLongClickListener {
            onAppLongClick?.invoke(app) ?: false
        }
    }

    override fun getItemCount(): Int = apps.size

    fun updateApps(newApps: List<AppInfo>) {
        this.apps = newApps
        notifyDataSetChanged()
    }

    fun submitList(newApps: List<AppInfo>) {
        updateApps(newApps)
    }
}
