update item set (total_wishes) = 
  (select count(*) as total from wish where item.id = wish.item_id group by item_id) 
  from wish where item.id = wish.item_id