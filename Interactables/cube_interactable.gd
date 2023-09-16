extends Interactable

func action_use():
	$MeshInstance3D.rotation.x += 1
	$MeshInstance3D.rotation.y += 2
	$MeshInstance3D.rotation.z -= 2
