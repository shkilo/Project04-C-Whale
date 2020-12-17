whale.contextMenus.create({
  id: "ADD_TASK",
  title: `할고래DO 할일로 추가`,
  contexts: ["selection"],
});

whale.alarms.onAlarm.addListener((alarm) => {
  whale.notifications.create({
    title: `할일: ${alarm.name}`,
    message: "CLICK !!",
    iconUrl: "images/icon.png",
    type: "basic",
  });
});

whale.notifications.onClicked.addListener(() => {
  whale.sidebarAction.show();
});

let handlerToRemove;

whale.runtime.onConnectExternal.addListener((port) => {
  const handleOnClicked = (info) => {
    if (info.menuItemId == "ADD_TASK") {
      port.postMessage(info);
    }
  };

  whale.contextMenus.onClicked.removeListener(handlerToRemove);
  whale.contextMenus.onClicked.addListener(handleOnClicked);
  handlerToRemove = handleOnClicked;
});

whale.runtime.onMessageExternal.addListener((message, _sender, sendResponse) => {
  switch (message.type) {
    case "getCurrentTabUrl":
      whale.tabs.query({ active: true, lastFocusedWindow: true }, (tabs) => {
        const currentTab = tabs[0];
        sendResponse({ url: currentTab.url, title: currentTab.title });
      });
      break;

    case "createAlarm":
      const { taskId, taskTitle, fireTime } = message.data;
      whale.storage.sync.set({ taskId: { taskTitle, fireTime } });
      whale.alarms.create(taskTitle, {
        when: fireTime,
      });
      break;

    case "createBookmark":
      const { folderTitle, bookmarks } = message.data;
      whale.bookmarks.create(
        {
          parentId: "1",
          title: folderTitle,
        },
        (newFolder) => {
          bookmarks.forEach((bookmark) => {
            whale.bookmarks.create({
              parentId: newFolder.id,
              title: bookmark.title,
              url: bookmark.url,
            });
          });
          sendResponse("북마크가 추가되었습니다.");
        }
      );
      break;
  }
});
