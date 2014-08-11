		function addNotification(team, result, isParseObject, promises, customMessage){
			//Create a notification record sent to user with pending invites
			var notification = {
				data: {
					message: customMessage, 
					senderType: NotificationModule.SenderType.Team, 
					senderId: team.id, 
					senderName: team.attributes.name, 
					senderImageUrl: team.attributes.picture
				},
				recipient: isParseObject ? result.get("user") : result.user,
				type: NotificationModule.Type.InvitationResponse,
				status: NotificationModule.Status.Unread,
				challenge: team.get("challenge"),
				requireAction: false,
				actionPerformed: null
			}
			promises.push(NotificationModule.save(notification));

			//Send a push notification
			var pushNotification = {
				text: notification.data.message,
				target: {
					type: PushNotificationModule.Target.User,
					user: notification.recipient
				},
				data: {
					type: notification.type
				}
			}
			promises.push(PushNotificationModule.send(pushNotification));
		}
