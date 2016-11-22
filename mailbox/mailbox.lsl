integer dropStatus;
integer useStatus;
string templateName;
list items;
key owner;
integer menuChannel;
integer handle;

default
{
  state_entry()
    {
      templateName = "message";
      menuChannel = (integer)llFrand(DEBUG_CHANNEL)*-1;
      dropStatus = FALSE;
      useStatus = FALSE;
      owner = llGetOwner();
      integer count = llGetInventoryNumber(INVENTORY_ALL);
      integer index;
      while (index < count)
	{
	  string itemName = llGetInventoryName(INVENTORY_ALL, index);
	  integer itemType = llGetInventoryType(itemName);
	  if (itemType != INVENTORY_SCRIPT && itemName != templateName)
	    {
	      items += [itemName];
	    }
	  ++index;
	}
    }

  on_rez(integer start_param)
    {
      llResetScript();
    }

  touch_start(integer total_number)
    {
      if (handle)
	{
	  llListenRemove(handle);
	  handle = FALSE;
	}
      key id = llDetectedKey(0);
      if (id == owner)
	{
	  handle=llListen(menuChannel,"","","");
	  llDialog(id,"郵便箱をどうしますか？",["受け取る","削除"],menuChannel);
	  llSetTimerEvent(10);
	}
      else if (useStatus == FALSE)
	{
	  dropStatus = TRUE;
	  llAllowInventoryDrop(dropStatus);
	  llSetTimerEvent(30);
	  llInstantMessage(id,"30秒以内ノートカードを入れてください。");
	  llGiveInventory(id,templateName);
	  useStatus = TRUE;
	}
      else
	{
	  llInstantMessage(id,"使用中です。暫くお待ちください。");
	}
    }

  listen(integer channel, string name, key id, string message)
    {
      if (handle)
	{
	  llListenRemove(handle);
	  handle = FALSE;
	}
      if (message == "受け取る")
	{
	  if (llGetListLength(items) > 0)
	    {
	      llGiveInventoryList(owner,llGetObjectName(),items);
	    }
	  else
	    {
	      llInstantMessage(owner,"郵便箱は空です。");
	    }
	}
      else if (message == "削除")
	{
	  integer index = llGetInventoryNumber(INVENTORY_ALL);
	  while (index)
	    {
	      --index;
	      string itemName = llGetInventoryName(INVENTORY_ALL, index);
	      integer itemType = llGetInventoryType(itemName);
	      if (itemType != INVENTORY_SCRIPT && itemName != templateName)
		{
		  llRemoveInventory(itemName);
		  index = llGetInventoryNumber(INVENTORY_ALL);
		}
	    }
	  items = [];
	}
      useStatus = FALSE;
    }

  changed(integer change)
    {
      if (change & CHANGED_ALLOWED_DROP)
    {
      dropStatus = FALSE;
      llAllowInventoryDrop(dropStatus);
      integer count = llGetInventoryNumber(INVENTORY_ALL);
      integer index;
      integer found = TRUE;
      while (index < count && found == TRUE)
        {
          string itemName = llGetInventoryName(INVENTORY_ALL, index);
          integer itemType = llGetInventoryType(itemName);
          if (llListFindList(items,[itemName]) == -1)
	    {
	      if (itemType != INVENTORY_NOTECARD)
            {
              llRemoveInventory(itemName);
            }
	      else
		{
		  items += [itemName];
		  llInstantMessage(owner,"新しいメッセージが届きました。");
		}
	      found = FALSE;
	    }
	  else
	    {
	      ++index;
	    }
        }
    }
      if (change & (CHANGED_OWNER | CHANGED_INVENTORY))
	{
	  llResetScript();
	}
    }

  timer()
    {
      llSetTimerEvent((float)FALSE);
      useStatus = FALSE;
      if (handle)
	{
	  llListenRemove(handle);
	  handle = FALSE;
	}
      if (dropStatus == TRUE)
	{
	  dropStatus = FALSE;
	  llAllowInventoryDrop(dropStatus);
	}
    }
}
