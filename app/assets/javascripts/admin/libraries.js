Array.prototype.unique = function(){
	
	var new_array = [];
	var index = 0;
	var value = null;
	
	for( count=0; count < this.length; count++){
		
		value = this[count];
		
		if( new_array.indexOf(value)==-1 ){
			new_array[index++] = value;
		}
		
	}
	
	return new_array;
	
};