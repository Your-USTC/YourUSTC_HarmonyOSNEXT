print('正在初始化...')

import torch
from torch.utils.data import Dataset, DataLoader
from PIL import Image
import os
import torch.nn as nn
import torch.nn.functional as F
from torchvision import transforms

SOURCE_DIR = './training source' # 训练数据路径
ALL_CHARS = '略' # 所有会出现的字符
CHAR_TO_INDEX = {char: i for i, char in enumerate(ALL_CHARS)}  # 字符到索引的映射
INDEX_TO_CHAR = {i: char for char, i in CHAR_TO_INDEX.items()} # 索引到字符的映射
NUM_CLASSES = len(ALL_CHARS) # 字符数量
IMAGE_HEIGHT = 70 # 高度
IMAGE_WIDTH = 160 # 宽度


class CaptchaDataset(Dataset):
    def __init__(self, image_dir, transform=None):
        self.image_dir = image_dir
        self.image_files = os.listdir(image_dir)
        self.transform = transform

    def __len__(self):
        return len(self.image_files)

    def __getitem__(self, idx):
        img_name = self.image_files[idx]
        img_path = os.path.join(self.image_dir, img_name)
        
        # 加载图像
        image = Image.open(img_path).convert('L') # 转换为灰度图
        
        if self.transform:
            image = self.transform(image)
        
        # 从文件名获取标签 (例如: '1145.png' -> '1145')
        label_str = img_name.split('.')[0] 
        
        # 标签编码：将4个字符转换为4个索引
        label = [CHAR_TO_INDEX[char] for char in label_str]
        label_tensor = torch.tensor(label, dtype=torch.long)

        return image, label_tensor

# 使用transforms
data_transform = transforms.Compose([
    transforms.Resize((IMAGE_HEIGHT, IMAGE_WIDTH)), # 调整到统一大小
    transforms.ToTensor(),
])

# 创建DataLoader
train_dataset = CaptchaDataset(image_dir=SOURCE_DIR, transform=data_transform)
train_loader = DataLoader(train_dataset, batch_size=64, shuffle=True)

class CaptchaCNN(nn.Module):
    def __init__(self, num_classes, input_height, input_width):
        super(CaptchaCNN, self).__init__()
        
        self.conv1 = nn.Conv2d(1, 32, kernel_size=3, padding=1)
        self.bn1 = nn.BatchNorm2d(32)
        self.pool1 = nn.MaxPool2d(2, 2)
        
        self.conv2 = nn.Conv2d(32, 64, kernel_size=3, padding=1)
        self.bn2 = nn.BatchNorm2d(64)
        self.pool2 = nn.MaxPool2d(2, 2)
        
        self.conv3 = nn.Conv2d(64, 128, kernel_size=3, padding=1)
        self.bn3 = nn.BatchNorm2d(128)
        self.pool3 = nn.MaxPool2d(2, 2)

        # 动态计算 flatten_size，实际是20480
        self.flatten_size = self._get_conv_output_size(input_height, input_width)
        print(f"展平大小: {self.flatten_size}")
        
        # 4个独立预测头
        self.fc1 = nn.Linear(self.flatten_size, num_classes) 
        self.fc2 = nn.Linear(self.flatten_size, num_classes) 
        self.fc3 = nn.Linear(self.flatten_size, num_classes) 
        self.fc4 = nn.Linear(self.flatten_size, num_classes)

    def _get_conv_output_size(self, H, W):
        # 创建一个虚拟输入 tensor
        dummy_input = torch.autograd.Variable(torch.rand(1, 1, H, W))
        
        # 只运行卷积层部分
        output = self.pool1(F.relu(self.bn1(self.conv1(dummy_input))))
        output = self.pool2(F.relu(self.bn2(self.conv2(output))))
        output = self.pool3(F.relu(self.bn3(self.conv3(output))))
        
        # 返回展平后的总元素数量 (Channels * Height * Width)
        return output.size(1) * output.size(2) * output.size(3)
        
    def forward(self, x):
        # 共享特征提取
        x = self.pool1(F.relu(self.bn1(self.conv1(x))))
        x = self.pool2(F.relu(self.bn2(self.conv2(x))))
        x = self.pool3(F.relu(self.bn3(self.conv3(x))))
        
        # 展平
        x = x.view(x.size(0), -1)
        
        # 4个独立预测头
        out1 = self.fc1(x)
        out2 = self.fc2(x)
        out3 = self.fc3(x)
        out4 = self.fc4(x)

        return (out1, out2, out3, out4)


def calculate_accuracy(outputs, labels):
    # 获取每个位置的预测类别
    predicted_labels = []
    for output in outputs:
        _, predicted = torch.max(output.data, 1)
        predicted_labels.append(predicted)

    predicted_labels = torch.stack(predicted_labels, dim=1) 
    
    # 字符准确率 (Character Accuracy)
    total_correct_chars = (predicted_labels == labels).sum().item()
    total_chars = labels.size(0) * labels.size(1) # batch_size * 4
    char_acc = total_correct_chars / total_chars
    
    # 整图准确率 (Image Accuracy)
    total_correct_images = (predicted_labels == labels).all(dim=1).sum().item()
    total_images = labels.size(0) # batch_size
    image_acc = total_correct_images / total_images
    
    return char_acc, image_acc

print(f'正在从 {SOURCE_DIR} 读取图片并进行训练...')

num_epochs = 10 # 其实可以提前结束
model = CaptchaCNN(NUM_CLASSES, IMAGE_HEIGHT, IMAGE_WIDTH) 
criterion = nn.CrossEntropyLoss()
optimizer = torch.optim.Adam(model.parameters(), lr=0.001)

device = torch.device("cpu") # 我的电脑是核显/(ㄒoㄒ)/~~
model.to(device)

for epoch in range(num_epochs):
    for i, (images, labels) in enumerate(train_loader):
        # 移动数据到设备
        images = images.to(device)
        
        # labels分成4个独立的tensor
        labels1 = labels[:, 0].to(device) # 第1个字符的所有标签
        labels2 = labels[:, 1].to(device) # 第2个字符的所有标签
        labels3 = labels[:, 2].to(device) # 第3个字符的所有标签
        labels4 = labels[:, 3].to(device) # 第4个字符的所有标签
        
        # 前向传播
        outputs = model(images)
        
        # 计算4个位置的损失，并相加
        loss1 = criterion(outputs[0], labels1)
        loss2 = criterion(outputs[1], labels2)
        loss3 = criterion(outputs[2], labels3)
        loss4 = criterion(outputs[3], labels4)
        
        total_loss = loss1 + loss2 + loss3 + loss4
        
        # 反向传播与优化
        optimizer.zero_grad()
        total_loss.backward()
        optimizer.step()
        
        # 打印训练信息
        print(f'Epoch [{epoch+1}/{num_epochs}], Step [{i+1}/{len(train_loader)}], Loss: {total_loss.item():.4f}')

SAVE_PATH = f'model loss {total_loss.item():.3f}.pth' # 保存路径
torch.save(model.state_dict(), SAVE_PATH) # 保存

print(f"本次训练权重已成功保存到 {SAVE_PATH}")

# --- 4. 图像预处理 (必须与训练时一致) ---

def predict_image(image_path, model, transform, device):
    # 加载图像并转换为灰度图
    image = Image.open(image_path).convert('L')
    
    # 预处理：应用Transform并增加Batch维度
    image_tensor = transform(image).unsqueeze(0).to(device)
    
    # 推理：关闭梯度计算 (加快速度并节省内存)
    with torch.no_grad():
        outputs = model(image_tensor)
    
    # 将模型的四个输出转换为字符
    predicted_chars = []
    
    for output in outputs:
        # 找到概率最大的类别索引
        _, predicted_index = torch.max(output.data, 1) 
        
        # 将索引转换为字符
        char = INDEX_TO_CHAR[predicted_index.item()]
        predicted_chars.append(char)
        
    return "".join(predicted_chars)

def predict_image_with_confidence(image_path, model, transform, device):
    # 加载图像并转换为灰度图
    image = Image.open(image_path).convert('L')
    
    # 预处理：应用Transform并增加Batch维度
    image_tensor = transform(image).unsqueeze(0).to(device)
    
    # 推理：关闭梯度计算 (加快速度并节省内存)
    with torch.no_grad():
        outputs = model(image_tensor) 
    
    predicted_chars = []
    char_confidences = [] # 存储每个字符的置信度

    # 计算Softmax并解码
    for output in outputs:
        # 将Logits转换为概率分布P
        probabilities = F.softmax(output, dim=1) 
        
        # 找到最大概率 (置信度) 及其对应的索引
        max_confidence, predicted_index = torch.max(probabilities, 1) 
        
        # 将置信度保存
        char_confidences.append(max_confidence.item())
        
        # 将索引转换为字符
        char = INDEX_TO_CHAR[predicted_index.item()]
        predicted_chars.append(char)
        
    # 几何平均计算整图置信度
    confidence_product = torch.prod(torch.tensor(char_confidences)).item()
    confidence_image = confidence_product ** (1 / len(char_confidences))

    return {
        "prediction": "".join(predicted_chars),
        "char_confidences": char_confidences,
        "image_confidence": confidence_image
    }

# 运行
if __name__ == '__main__':
    print('\n请输入图片文件名，不含.png | 输入exit退出', end = "")
    number_count = 0
    while True:
        number_count += 1
        print('\n# Task', number_count)
        test_image_path = input('>') + '.png'
        if test_image_path == 'exit.png':
            exit(0)

        try:
            result = predict_image_with_confidence(test_image_path, model, data_transform, device)
            print(f"图像 '{test_image_path}' 的识别结果是: {result['prediction']}")
            print(f"单个字符的置信度: {result['char_confidences']}")
            print(f"总置信度: {result['image_confidence']}")
        except FileNotFoundError:
            print(f"错误：未找到文件 {test_image_path}，请检查路径")