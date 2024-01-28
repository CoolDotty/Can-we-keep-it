extends Pet


func _physics_process(delta):
	if _disabled:
		return
	super(delta)
	weight = 1.8
