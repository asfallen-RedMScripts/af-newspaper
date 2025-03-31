let currentImageUrl = '';
const debug = false;
let reporterPanelWasVisible = false;
// Popup Aç/Kapat
function openImagePopup() {
    document.getElementById('imagePopup').style.display = 'block';
}
function closePopup() {
    document.getElementById('imagePopup').style.display = 'none';
}
function formatWesternDate() {
    const months = [
        "Ocak", "Şubat", "Mart", "Nisan", "Mayıs", "Haziran",
        "Temmuz", "Ağustos", "Eylül", "Ekim", "Kasım", "Aralık"
    ];
    
    const today = new Date();
    let day = today.getDate();
    const month = months[today.getMonth()];
    const year = 1903; 
    
    return `${day} ${month} ${year}`;
}


function loadNewspaperContent(content) {
    const articleBody = document.getElementById('articleBody');
    const articleDate = document.getElementById('articleDate');

    if (articleBody && articleDate) {
        articleBody.innerHTML = content; // İçeriği yükle
        articleDate.textContent = formatWesternDate(); // Tarihi gazetenin altına ekle
    } else {
        console.error('articleBody veya articleDate elementi bulunamadı!');
    }
}

// Resim Ekle
function addImage() {
    const imageUrl = document.getElementById('imageUrl').value;
    if (imageUrl) {
        currentImageUrl = imageUrl;
        closePopup();
        // Haber gövdesine ek resim
        document.getElementById('articleBody').innerHTML += `
            <img src="${imageUrl}" alt="Opsiyonel Resim" style="display:block; margin:20px auto; border:2px solid #3d2b1f;" />
        `;
    }
}

// ESC ile kapatma
document.addEventListener('keyup', function (event) {
    if (event.key === "Escape") {
        closeNewspaperNUI();
    }
});

// Gazeteyi kapatma (X veya ESC)
function closeNewspaperNUI() {

    closeCopyPopup();
    
    fetch(`https://${GetParentResourceName()}/closeNewspaper`, {
        method: 'POST',
        headers: { 'Content-Type': 'application/json; charset=UTF-8' },
        body: JSON.stringify({})
    })
    .then(res => res.text()) 
    .then(() => {
        // Gazete okuma alanını sıfırla
        document.getElementById('articleTitle').innerText = '';
        document.getElementById('articleBody').innerText = '';
        document.getElementById('articleImage').src = '';
        document.getElementById('articleImage').style.display = 'none';
        document.getElementById('articleDate').innerText = '';
        document.getElementById('newspaperContainer').style.display = 'none';
        
        // Reporter panelini de kapat
        const reporterPanel = document.getElementById('reporterPanel');
        if(reporterPanel) {
            reporterPanel.style.display = 'none';
        }

        // Client tarafına NUI'yi kapatma isteği gönder
        fetch(`https://${GetParentResourceName()}/requestCloseNUI`, {
            method: 'POST',
            headers: { 'Content-Type': 'application/json; charset=UTF-8' },
            body: JSON.stringify({})
        });
    })
    .catch(err => console.error('NUI kapatma hatası:', err));
}

// Yeni gazete ekleme (publishStory) 
function publishNewStory() {
    const title = document.getElementById('newTitle').value;
    const body = document.getElementById('newBody').value;
    const image = document.getElementById('newImage').value;

    fetch(`https://${GetParentResourceName()}/publishStory`, {
        method: 'POST',
        headers: { 'Content-Type': 'application/json; charset=UTF-8' },
        body: JSON.stringify({
            title: title,
            body: body,
            image: image
        })
    }).then(() => {
        // İşlem bitince eski gazeteleri listeleyin
        loadOldNewspapers();
    }).catch(err => console.error('Yeni gazete ekleme hatası:', err));
}

// Eski gazeteleri listeleme
function loadOldNewspapers() {
    fetch(`https://${GetParentResourceName()}/getAllStories`, {
        method: 'POST',
        headers: { 'Content-Type': 'application/json; charset=UTF-8' }
    })
    .then(res => res.json())
    .then(data => {
        const oldNewsDiv = document.getElementById('oldNewspapers');
        oldNewsDiv.innerHTML = ''; // Temizle

        data.forEach(story => {
            const storyDiv = document.createElement('div');
            storyDiv.style.borderBottom = '1px solid #aaa';
            storyDiv.style.marginBottom = '5px';
            storyDiv.innerHTML = `
                <strong>ID: ${story.id}</strong><br>
                <span>Başlık: ${story.title}</span><br>
                <span>Tarih: ${story.date}</span><br>
                <button onclick="viewNewspaper(${story.id})">Görüntüle</button>
                <button onclick="copyNewspaper(${story.id})">Kopya Al</button>
            `;
            oldNewsDiv.appendChild(storyDiv);
        });
    })
    .catch(err => console.error('Eski gazeteleri listeleme hatası:', err));
}

function viewNewspaper(newspaperId) {
    document.getElementById('reporterPanel').style.display = 'none';
    fetch(`https://${GetParentResourceName()}/openVersion`, {
         method: 'POST',
         headers: { 'Content-Type': 'application/json; charset=UTF-8' },
         body: JSON.stringify({ newspaperId: newspaperId })
    });
}


     // Set up newspaper when loaded
     document.addEventListener('DOMContentLoaded', function() {
        // Set the date
        document.getElementById('articleDate').textContent = formatWesternDate();
        
        // Prevent text selection throughout the document
        document.addEventListener('selectstart', function(e) {
            e.preventDefault();
            return false;
        });
        
        // Prevent context menu (right-click)
        document.addEventListener('contextmenu', function(e) {
            e.preventDefault();
            return false;
        });
    });



// NUI mesajlarını dinle
// NUI mesajlarını dinle
window.addEventListener('message', (event) => {
    if (event.data.action === 'openNewspaper') {
        // Gazete verisini al
        const news = event.data.stories && event.data.stories[0];
        document.getElementById('newspaperContainer').style.display = 'block';

        if (!news) {
            document.getElementById('articleTitle').innerText = '';
            document.getElementById('articleBody').innerText = 'Gazete verisi bulunamadı.';
            return;
        }

        // Gazete içeriğini yükle
        document.getElementById('articleTitle').innerText = news.title || '';
        document.getElementById('articleDate').innerText = news.date || '';

        // İçeriği yükle ve tarihi içeriğin sonuna ekle
        loadNewspaperContent(news.body || '');

        // Resmi yükle (eğer varsa)
        if (news.image && news.image !== "") {
            const articleImage = document.getElementById('articleImage');
            articleImage.src = news.image;
            articleImage.style.display = 'block';
        } else {
            document.getElementById('articleImage').style.display = 'none';
        }
    }
    else if (event.data.action === 'toggleReporterPanel') {
        // Öncelikle gazete okuma alanını gizleyin ve temizleyin
        const newspaperContainer = document.getElementById('newspaperContainer');
        newspaperContainer.style.display = 'none';
        document.getElementById('articleTitle').innerText = '';
        document.getElementById('articleBody').innerText = '';
        document.getElementById('articleImage').src = '';
        document.getElementById('articleImage').style.display = 'none';
        document.getElementById('articleDate').innerText = '';

        // Reporter paneli açmadan önce form alanlarını sıfırlayın
        document.getElementById('newTitle').value = '';
        document.getElementById('newBody').value = '';
        document.getElementById('newImage').value = '';
        document.getElementById('newVersion').value = '';

        // Paneli ortada gösterin (CSS düzenlemesi ile zaten ortalanacak)
        document.getElementById('reporterPanel').style.display = 'block';
        
        // Eski haberleri listeleyin
        loadOldNewspapers();
    }
});

function copyNewspaper(newspaperId) {
    const copyPopup = document.getElementById('copyPopup');
    const reporterPanel = document.getElementById('reporterPanel');
    
    if (copyPopup) {
        // Dataset anahtarını newspaperId olarak ayarla
        copyPopup.dataset.newspaperId = newspaperId;
        copyPopup.style.display = 'block';
        copyPopup.style.zIndex = '2000';
        copyPopup.style.position = 'fixed';
        copyPopup.style.top = '50%';
        copyPopup.style.left = '50%';
        copyPopup.style.transform = 'translate(-50%, -50%)';
        copyPopup.style.background = '#f4e9d5';
        copyPopup.style.padding = '20px';
        copyPopup.style.border = '3px solid #573e1f';
        copyPopup.style.boxShadow = '0 0 10px rgba(0,0,0,0.6)';
        
        // Eğer reporter panel görünüyorsa, saklayıp gizleyelim
        if (reporterPanel) {
            if (reporterPanel.style.display !== 'none') {
                reporterPanelWasVisible = true;
                reporterPanel.style.display = 'none';
                if (debug) console.log("copyNewspaper: Reporter panel gizlendi.");
            }
        }
        
        // Kopya sayısı inputunu sıfırla
        const copyCountInput = document.getElementById('copyCount');
        if (copyCountInput) {
            copyCountInput.value = '1';
        }
        
        if (debug) console.log("copyNewspaper: Pop-up açıldı.");
    } else {
        console.error('copyPopup element not found in the DOM!');
    }
}

function closeCopyPopup() {
    const copyPopup = document.getElementById('copyPopup');
    const reporterPanel = document.getElementById('reporterPanel');
    
    if (copyPopup) {
        copyPopup.style.display = 'none';
        if (debug) console.log("closeCopyPopup: Pop-up kapatıldı.");
    }
    
    // Reporter panel daha önceden görünüyorduysa, eski haline getir
    if (reporterPanel && reporterPanelWasVisible) {
        reporterPanel.style.display = 'block';
        reporterPanelWasVisible = false;
        if (debug) console.log("closeCopyPopup: Reporter panel yeniden gösterildi.");
    }
}
function confirmCopy() {
    const copyPopup = document.getElementById('copyPopup');
    if (!copyPopup) {
        if (debug) console.error('copyPopup element not found!');
        return;
    }

    const newspaperId = copyPopup.dataset.newspaperId;
    const copyCount = parseInt(document.getElementById('copyCount').value) || 1;

    if (!copyCount || copyCount < 1) {
        if (debug) console.error("Geçerli bir kopya sayısı girilmedi.");
        return;
    }

    fetch(`https://${GetParentResourceName()}/copyNewspaper`, {
        method: 'POST',
        headers: { 'Content-Type': 'application/json; charset=UTF-8' },
        body: JSON.stringify({
            newspaperId: newspaperId,
            copyCount: copyCount
        })
    })
    .then(res => res.json())
    .then(data => {
        closeCopyPopup();
        if (debug) console.log(data.message || "Kopyalama işlemi tamamlandı.");
    })
    .catch(err => {
        if (debug) console.error('Gazete kopyalama hatası:', err);
    });
}
