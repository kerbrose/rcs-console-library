package it.ht.rcs.console.accounting.controller
{
  import it.ht.rcs.console.DB;
  import it.ht.rcs.console.ObjectUtils;
  import it.ht.rcs.console.accounting.model.Group;
  import it.ht.rcs.console.accounting.model.Session;
  import it.ht.rcs.console.accounting.model.User;
  import it.ht.rcs.console.controller.ItemManager;
  import it.ht.rcs.console.search.model.SearchItem;
  import it.ht.rcs.console.utils.AlertPopUp;
  
  import locale.R;
  
  import mx.collections.ArrayCollection;
  import mx.events.PropertyChangeEvent;
  import mx.rpc.events.ResultEvent;
  
  public class UserManager extends ItemManager
  {

    public function UserManager() { super(User); }
    
    private static var _instance:UserManager = new UserManager();
    public static function get instance():UserManager { return _instance; }
    
    override public function refresh():void
    {
      super.refresh();
      loadData();
    }
    
    private function loadData():void
    {
      DB.instance.session.all(function(e1:ResultEvent):void
      {
        DB.instance.user.all(function(e2:ResultEvent):void
        {
          clear();
          for each (var item:* in e2.result.source)
            addItem(item);
          
          for each (var session:Session in e1.result)
            for each (var user:User in e2.result)
              if (session.user._id == user._id) {
                user.session = session;
                break;
              }

          dispatchDataLoadedEvent();
        });
      });
    }
    
    override protected function onItemRemove(o:*):void
    {
      for each (var g:String in (o as User).group_ids) {
        var group:Group = GroupManager.instance.getItem(g);
        group.user_ids.removeItemAt(group.user_ids.getItemIndex(o._id));
        group.dispatchEvent(new PropertyChangeEvent(PropertyChangeEvent.PROPERTY_CHANGE));
      }
      DB.instance.user.destroy(o);
    }
    
    override protected function onItemUpdate(event:*):void
    { 
      if (event.property == 'session') return;
      var property:Object = new Object();
      property[event.property] = event.newValue is ArrayCollection ? event.newValue.source : event.newValue;
      DB.instance.user.update(event.source, property);
    }
    
    public function addUser(user:User, callback:Function):void
    {
      DB.instance.user.create(ObjectUtils.toHash(user), function (e:ResultEvent):void {
        var u:User = e.result as User;
        addItem(u);
        callback(u);
      });
    }
    
    public function show(id:String, onResult:Function=null):void
    {
      DB.instance.user.show(id, function(e:ResultEvent):void {
        if (onResult != null)
          onResult(e.result as User);
      });
    }
    
    public function changePassword(user:User, password:String):void
    {
      DB.instance.user.update(user, {pass: password}, function (e:ResultEvent):void {
        AlertPopUp.show(R.get('PASSWORD_CHANGED'));
      });
    }
    
    public function update(user:User, properties:Object):void
    {
      DB.instance.user.update(user, properties);
    }

    public function add_recent(user:User, item:SearchItem):void
    {
      DB.instance.user.add_recent(user, item._id, function(e:ResultEvent):void {
        user.recent_ids = (e.result as User).recent_ids;
      });
    }
    
    public function send_message(id:String, text:String):void
    {
      DB.instance.user.message(id, text);
    }
    
  }
  
}