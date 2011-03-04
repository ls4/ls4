//
// LS4 Client for Java
//
// Copyright (C) 2010-2011 FURUHASHI Sadayuki
//
//    Licensed under the Apache License, Version 2.0 (the "License");
//    you may not use this file except in compliance with the License.
//    You may obtain a copy of the License at
//
//        http://www.apache.org/licenses/LICENSE-2.0
//
//    Unless required by applicable law or agreed to in writing, software
//    distributed under the License is distributed on an "AS IS" BASIS,
//    WITHOUT WARRANTIES OR CONDITIONS OF ANY KIND, either express or implied.
//    See the License for the specific language governing permissions and
//    limitations under the License.
//
package net.sourceforge.ls4;

import java.util.Map;
import org.msgpack.template.FieldOption;
import org.msgpack.annotation.MessagePackMessage;

@MessagePackMessage(FieldOption.NULLABLE)
public class StoredObject {
	public byte[] data;
	public Map<String, String> attributes;

	public StoredObject() {
	}

	public boolean isFound() {
		return data != null && attributes != null;
	}

	public StoredObject(byte[] data, Map<String, String> attributes) {
		this.data = data;
		this.attributes = attributes;
	}

	public byte[] getData() {
		return data;
	}

	public Map<String, String> getAttributes() {
		return attributes;
	}
}

