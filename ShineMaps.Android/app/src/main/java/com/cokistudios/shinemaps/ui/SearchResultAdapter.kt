package com.cokistudios.shinemaps.ui

import android.view.LayoutInflater
import android.view.View
import android.view.ViewGroup
import android.widget.ImageView
import android.widget.TextView
import androidx.recyclerview.widget.RecyclerView
import com.cokistudios.shinemaps.R
import com.cokistudios.shinemaps.data.SearchResult

class SearchResultAdapter(
    private val onItemClick: (SearchResult) -> Unit
) : RecyclerView.Adapter<SearchResultAdapter.ViewHolder>() {

    private val items = mutableListOf<SearchResult>()

    fun submitList(newItems: List<SearchResult>) {
        items.clear()
        items.addAll(newItems)
        notifyDataSetChanged()
    }

    override fun onCreateViewHolder(parent: ViewGroup, viewType: Int): ViewHolder {
        val view = LayoutInflater.from(parent.context).inflate(R.layout.item_search_result, parent, false)
        return ViewHolder(view)
    }

    override fun onBindViewHolder(holder: ViewHolder, position: Int) {
        val item = items[position]
        holder.bind(item)
    }

    override fun getItemCount(): Int = items.size

    inner class ViewHolder(itemView: View) : RecyclerView.ViewHolder(itemView) {
        private val ivIcon: ImageView = itemView.findViewById(R.id.ivPlaceIcon)
        private val tvTitle: TextView = itemView.findViewById(R.id.tvPlaceTitle)
        private val tvAddress: TextView = itemView.findViewById(R.id.tvPlaceAddress)
        private val tvDistance: TextView = itemView.findViewById(R.id.tvPlaceDistance)

        fun bind(result: SearchResult) {
            tvTitle.text = result.title
            tvAddress.text = result.address

            if (result.iconRes != null) {
                ivIcon.setImageResource(result.iconRes)
            } else {
                ivIcon.setImageResource(R.drawable.ic_pin_drop)
            }

            val distanceStr = result.formattedDistance
            if (!distanceStr.isNullOrBlank()) {
                tvDistance.text = distanceStr
                tvDistance.visibility = View.VISIBLE
            } else {
                tvDistance.visibility = View.GONE
            }

            itemView.setOnClickListener { onItemClick(result) }
        }
    }
}
